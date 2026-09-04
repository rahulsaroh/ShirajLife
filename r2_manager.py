import os
import sys
import datetime
import hashlib
import hmac
import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET

# Load environment variables from .env
env_path = os.path.join(os.path.dirname(__file__), ".env")
env_vars = {}
if os.path.exists(env_path):
    with open(env_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                env_vars[k.strip()] = v.strip()

ACCESS_KEY = env_vars.get("R2_ACCESS_KEY_ID")
SECRET_KEY = env_vars.get("R2_SECRET_ACCESS_KEY")
ENDPOINT = env_vars.get("R2_ENDPOINT", "")
ACCOUNT_ID = env_vars.get("CLOUDFLARE_ACCOUNT_ID")

if not ACCESS_KEY or not SECRET_KEY or not ENDPOINT:
    print("Error: Missing R2 credentials in .env file.")
    sys.exit(1)

host = urllib.parse.urlparse(ENDPOINT).netloc
region = "auto"
service = "s3"

def sign(key, msg):
    return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()

def get_signature_key(key, date_stamp, region_name, service_name):
    k_date = sign(("AWS4" + key).encode("utf-8"), date_stamp)
    k_region = sign(k_date, region_name)
    k_service = sign(k_region, service_name)
    k_signing = sign(k_service, "aws4_request")
    return k_signing

def send_s3_request(method="GET", bucket="", key="", payload=b"", headers_extra=None):
    now = datetime.datetime.now(datetime.timezone.utc)
    amz_date = now.strftime("%Y%m%dT%H%M%SZ")
    date_stamp = now.strftime("%Y%m%d")

    path = "/"
    if bucket:
        path += bucket + "/"
    if key:
        path += urllib.parse.quote(key.lstrip("/"))

    payload_hash = hashlib.sha256(payload).hexdigest()

    headers = {
        "Host": host,
        "x-amz-date": amz_date,
        "x-amz-content-sha256": payload_hash,
    }
    if headers_extra:
        headers.update(headers_extra)

    canonical_headers = "".join(f"{k.lower()}:{v.strip()}\n" for k, v in sorted(headers.items()))
    signed_headers = ";".join(sorted(k.lower() for k in headers.keys()))

    canonical_request = f"{method}\n{path}\n\n{canonical_headers}\n{signed_headers}\n{payload_hash}"
    algorithm = "AWS4-HMAC-SHA256"
    credential_scope = f"{date_stamp}/{region}/{service}/aws4_request"
    string_to_sign = f"{algorithm}\n{amz_date}\n{credential_scope}\n{hashlib.sha256(canonical_request.encode('utf-8')).hexdigest()}"

    signing_key = get_signature_key(SECRET_KEY, date_stamp, region, service)
    signature = hmac.new(signing_key, string_to_sign.encode("utf-8"), hashlib.sha256).hexdigest()

    auth_header = f"{algorithm} Credential={ACCESS_KEY}/{credential_scope}, SignedHeaders={signed_headers}, Signature={signature}"
    headers["Authorization"] = auth_header

    req_url = f"{ENDPOINT.rstrip('/')}{path}"
    req = urllib.request.Request(req_url, data=payload if method in ("PUT", "POST") else None, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()

def list_buckets():
    print(f"Connecting to Cloudflare R2: {ENDPOINT}...")
    status, body = send_s3_request("GET")
    if status == 200:
        print("Successfully authenticated with Cloudflare R2!")
        root = ET.fromstring(body.decode("utf-8"))
        buckets = [b.find("{http://s3.amazonaws.com/doc/2006-03-01/}Name").text for b in root.findall(".//{http://s3.amazonaws.com/doc/2006-03-01/}Bucket")]
        if buckets:
            print(f"Found {len(buckets)} bucket(s): {', '.join(buckets)}")
        else:
            print("No buckets found yet. You can create an R2 bucket in Cloudflare Dashboard > R2.")
    else:
        print(f"R2 API Error ({status}): {body.decode('utf-8', errors='replace')}")

if __name__ == "__main__":
    list_buckets()
