const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")("sk_test_PLACEHOLDER_KEY"); // Replace with your actual Stripe Secret Key

admin.initializeApp();
const db = admin.firestore();

// Secret to verify Stripe Webhooks
const endpointSecret = "whsec_PLACEHOLDER_SECRET"; // Replace with your webhook signing secret

exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  let event;

  try {
    // Verify the webhook signature
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err) {
    console.error(`Webhook signature verification failed: ${err.message}`);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the checkout.session.completed event
  if (event.type === "checkout.session.completed") {
    const session = event.data.object;
    
    // We pass the Firebase UID in the client_reference_id field of the Stripe Payment Link
    const uid = session.client_reference_id;

    if (uid) {
      console.log(`Payment successful for user: ${uid}`);
      try {
        // Update the user's subscription status to active
        await db.collection("users").doc(uid).update({
          subscriptionStatus: "active",
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`Successfully updated subscription status for ${uid}`);
      } catch (error) {
        console.error(`Error updating Firestore for uid ${uid}:`, error);
        return res.status(500).send("Database error");
      }
    } else {
      console.error("No client_reference_id found in the session.");
    }
  }

  // Return a 200 response to acknowledge receipt of the event
  res.json({ received: true });
});
