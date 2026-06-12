/**
 * Shiraj Life - Shared Authentication & Persistence Script
 * Handles initialization of default client data, login state, and header synchronizations.
 * Migrated to support Firebase Auth & Firestore with local storage fallback.
 */

(function () {
    // 1. DEFAULT DATA CONFIGURATION
    const DATA_VERSION = "v2";

    const DEFAULT_CLIENTS = [
        {
            id: "ritu",
            name: "Ritu Designer",
            username: "ritu",
            password: "ritu123",
            service: "Boutique & Fashion Landing Page",
            totalContract: 120000,
            paidAmount: 85000,
            balanceAmount: 35000,
            progress: 75,
            status: "In Progress",
            renewalDate: "2027-06-10",
            details: "Designing an elegant, premium web showcase with tailoring inquiry integrations.",
            timeline: [
                { label: "Requirements Gathering", completed: true },
                { label: "Figma UI/UX Mockups", completed: true },
                { label: "Frontend Coding (HTML/CSS)", completed: true },
                { label: "Custom Inquiry Form Integration", completed: false },
                { label: "Final Review & Launch", completed: false }
            ],
            messages: [
                { sender: "Shiraj", text: "Hi Ritu, I have completed the responsive couture layouts. Let me know what you think!", time: "2026-06-10 14:30" }
            ]
        },
        {
            id: "opulence",
            name: "Opulence Salon",
            username: "opulence",
            password: "opulence123",
            service: "Bespoke Facial & Hair Care Portal",
            totalContract: 180000,
            paidAmount: 180000,
            balanceAmount: 0,
            progress: 100,
            status: "Completed",
            renewalDate: "2027-06-08",
            details: "Premium web application highlighting bespoke facials, hair care, and bridal catalogs.",
            timeline: [
                { label: "Scope & Site Structure", completed: true },
                { label: "Bespoke Styling Guidelines", completed: true },
                { label: "Development & Asset Sourcing", completed: true },
                { label: "Bridal Package Builder Page", completed: true },
                { label: "Live Deployment", completed: true }
            ],
            messages: [
                { sender: "Shiraj", text: "The web app is deployed and live! Thanks for the smooth cooperation.", time: "2026-06-08 11:20" }
            ]
        },
        {
            id: "ironpulse",
            name: "IronPulse Gym",
            username: "ironpulse",
            password: "ironpulse123",
            service: "Interactive Gym Platform",
            totalContract: 150000,
            paidAmount: 50000,
            balanceAmount: 100000,
            progress: 40,
            status: "In Progress",
            renewalDate: "2027-05-01",
            details: "High-performance training class scheduling and membership card selector dashboard.",
            timeline: [
                { label: "Project Initialization", completed: true },
                { label: "Wireframes & Tier List Design", completed: true },
                { label: "Schedule Calendar Feature", completed: false },
                { label: "Client Admin Panel Integration", completed: false },
                { label: "Beta Testing & Launch", completed: false }
            ],
            messages: [
                { sender: "Shiraj", text: "Yes, absolutely. Designing it with CSS Grid to stack cleanly on mobile devices.", time: "2026-06-11 11:00" }
            ]
        }
    ];

    const ADMIN_CREDENTIALS = {
        username: "admin",
        password: "admin123"
    };

    // 2. FIREBASE INTEGRATION SETUP
    // User will paste their credentials here. If they are placeholder values, fallback to localStorage.
    const firebaseConfig = {
        apiKey: "YOUR_API_KEY_HERE",
        authDomain: "YOUR_AUTH_DOMAIN_HERE",
        projectId: "YOUR_PROJECT_ID_HERE",
        storageBucket: "YOUR_STORAGE_BUCKET_HERE",
        messagingSenderId: "YOUR_MESSAGING_SENDER_ID_HERE",
        appId: "YOUR_APP_ID_HERE"
    };

    const isFirebaseConfigured = firebaseConfig && 
        firebaseConfig.apiKey && 
        firebaseConfig.apiKey !== "YOUR_API_KEY_HERE" && 
        firebaseConfig.apiKey !== "";

    let isFirebase = false;

    if (isFirebaseConfigured && typeof firebase !== "undefined") {
        try {
            firebase.initializeApp(firebaseConfig);
            isFirebase = true;
            console.log("Firebase App Initialized successfully.");
        } catch (e) {
            console.error("Firebase App initialization failed:", e);
        }
    }

    // 3. DATABASE INITIALIZATION (LOCAL FALLBACK)
    if (!localStorage.getItem("shiraj_clients_data") || localStorage.getItem("shiraj_data_version") !== DATA_VERSION) {
        localStorage.setItem("shiraj_clients_data", JSON.stringify(DEFAULT_CLIENTS));
        localStorage.setItem("shiraj_data_version", DATA_VERSION);
    }

    // 4. AUTHENTICATION SERVICES
    window.ShirajAuth = {
        isFirebase: isFirebase,

        // Authenticate admin or client
        login: async function (usernameOrEmail, password, role) {
            usernameOrEmail = usernameOrEmail.trim().toLowerCase();
            password = password.trim();

            if (this.isFirebase) {
                // Determine email address
                let email = usernameOrEmail;
                if (!email.includes("@")) {
                    email = `${usernameOrEmail}@shirajlife.com`;
                }

                try {
                    const userCredential = await firebase.auth().signInWithEmailAndPassword(email, password);
                    const user = userCredential.user;

                    // Query firestore to check role and metadata
                    const db = firebase.firestore();
                    let userDoc = await db.collection("users").doc(user.uid).get();

                    if (!userDoc.exists) {
                        // Special fallback: if this is the admin email logging in for the first time, auto-create the doc
                        if (email === "admin@shirajlife.com" || usernameOrEmail === "admin") {
                            await db.collection("users").doc(user.uid).set({
                                email: email,
                                role: "admin",
                                name: "Shiraj (Admin)"
                            });
                            userDoc = await db.collection("users").doc(user.uid).get();
                        } else {
                            throw new Error("User metadata profile does not exist in Firestore.");
                        }
                    }

                    const userData = userDoc.data();

                    // If a specific role was expected (e.g. login form selection) and user role doesn't match
                    if (role && userData.role !== role) {
                        await firebase.auth().signOut();
                        return { success: false, message: `Access denied. Expected ${role} privileges.` };
                    }

                    const sessionUser = {
                        uid: user.uid,
                        username: usernameOrEmail.split("@")[0],
                        email: email,
                        role: userData.role,
                        name: userData.name || (userData.role === "admin" ? "Shiraj (Admin)" : "Client"),
                        clientId: userData.clientId || null
                    };

                    localStorage.setItem("shiraj_auth_user", JSON.stringify(sessionUser));

                    // If admin is logged in, seed default data if database is empty
                    if (userData.role === "admin") {
                        await this.seedDefaultDataIfEmpty();
                    }

                    return { success: true };
                } catch (error) {
                    console.error("Firebase Login Error:", error);
                    let errMsg = "Login failed. Please check credentials.";
                    if (error.code === "auth/user-not-found" || error.code === "auth/wrong-password") {
                        errMsg = "Incorrect username or password.";
                    } else if (error.message) {
                        errMsg = error.message;
                    }
                    return { success: false, message: errMsg };
                }
            } else {
                // LOCAL STORAGE FALLBACK
                if (role === "admin") {
                    if (usernameOrEmail === ADMIN_CREDENTIALS.username && password === ADMIN_CREDENTIALS.password) {
                        const sessionUser = {
                            username: ADMIN_CREDENTIALS.username,
                            role: "admin",
                            name: "Shiraj (Admin)"
                        };
                        localStorage.setItem("shiraj_auth_user", JSON.stringify(sessionUser));
                        return { success: true };
                    }
                } else {
                    const clients = this.getClients();
                    const client = clients.find(c => c.username.toLowerCase() === usernameOrEmail && c.password === password);
                    if (client) {
                        const sessionUser = {
                            username: client.username,
                            role: "client",
                            clientId: client.id,
                            name: client.name
                        };
                        localStorage.setItem("shiraj_auth_user", JSON.stringify(sessionUser));
                        return { success: true };
                    }
                }
                return { success: false, message: "Invalid username or password." };
            }
        },

        // Log out the current user
        logout: async function () {
            localStorage.removeItem("shiraj_auth_user");
            if (this.isFirebase) {
                try {
                    await firebase.auth().signOut();
                } catch (e) {
                    console.error("Firebase Auth SignOut failed:", e);
                }
            }
            window.location.href = "login.html";
        },

        // Retrieve current logged-in user (reads from localStorage cache instantly to prevent async redirect flickers)
        getCurrentUser: function () {
            const userStr = localStorage.getItem("shiraj_auth_user");
            return userStr ? JSON.parse(userStr) : null;
        },

        // Check auth and redirect if needed
        requireAuth: function (allowedRole) {
            const user = this.getCurrentUser();
            if (!user) {
                window.location.href = "login.html";
                return null;
            }
            if (allowedRole && user.role !== allowedRole) {
                if (user.role === "admin") {
                    window.location.href = "admin-dashboard.html";
                } else {
                    window.location.href = "client-dashboard.html";
                }
                return null;
            }
            return user;
        },

        // Get all clients
        getClients: function () {
            // Even when using Firebase, we pull from the local cached copy in localStorage for immediate synchronous rendering.
            // A background Firestore snapshot listener keeps this cache perfectly updated in real-time.
            return JSON.parse(localStorage.getItem("shiraj_clients_data")) || [];
        },

        // Save entire list of clients (Optimistic UI update, saves locally then pushes asynchronously to Firebase if active)
        saveClients: function (clientsList) {
            localStorage.setItem("shiraj_clients_data", JSON.stringify(clientsList));
            window.dispatchEvent(new Event("storage"));

            if (this.isFirebase) {
                const db = firebase.firestore();
                // Push each client document to Firestore
                clientsList.forEach(client => {
                    db.collection("clients").doc(client.id).set(client)
                        .catch(err => console.error("Firestore sync error for client " + client.id, err));
                });
            }
        },

        getClientById: function (id) {
            const clients = this.getClients();
            return clients.find(c => c.id === id) || null;
        },

        // Create client account in Firebase Auth & Firestore (Used by admin dashboard)
        registerNewClient: async function (clientObj) {
            if (!this.isFirebase) {
                const clients = this.getClients();
                clients.push(clientObj);
                this.saveClients(clients);
                return { success: true };
            }

            const username = clientObj.username.toLowerCase();
            const email = `${username}@shirajlife.com`;
            const password = clientObj.password;

            // Use a secondary Firebase app instance to register client credentials
            // This prevents logging out the current admin session.
            const secondaryApp = firebase.initializeApp(firebaseConfig, `SecondaryApp_${Date.now()}`);
            try {
                // 1. Create client Auth credential
                const userCredential = await secondaryApp.auth().createUserWithEmailAndPassword(email, password);
                const uid = userCredential.user.uid;

                const db = firebase.firestore();
                
                // 2. Write to Firestore /users collection mapping this user to client role and ID
                await db.collection("users").doc(uid).set({
                    email: email,
                    role: "client",
                    clientId: clientObj.id,
                    name: clientObj.name
                });

                // 3. Write project profile to Firestore /clients collection
                await db.collection("clients").doc(clientObj.id).set(clientObj);

                // Sign out client session on the secondary instance and delete it
                await secondaryApp.auth().signOut();
                return { success: true };
            } catch (error) {
                console.error("Firebase Client Creation Error:", error);
                return { success: false, message: error.message };
            } finally {
                await secondaryApp.delete();
            }
        },

        // Delete client document in Firestore
        deleteClientFirestore: async function (clientId) {
            if (this.isFirebase) {
                try {
                    const db = firebase.firestore();
                    await db.collection("clients").doc(clientId).delete();
                    
                    // Note: We can't delete auth credentials from client-side SDK without user credentials.
                    // The client document is removed and their /users role metadata is cleared.
                    const userSnapshot = await db.collection("users").where("clientId", "==", clientId).get();
                    userSnapshot.forEach(async (doc) => {
                        await db.collection("users").doc(doc.id).delete();
                    });
                } catch (e) {
                    console.error("Firestore client delete error:", e);
                }
            }
        },

        // Seed default client data to Firestore if the DB is blank (runs post-login)
        seedDefaultDataIfEmpty: async function () {
            if (!this.isFirebase) return;
            try {
                const db = firebase.firestore();
                const snapshot = await db.collection("clients").limit(1).get();
                if (snapshot.empty) {
                    console.log("Firestore database is empty. Seeding default clients...");
                    for (const client of DEFAULT_CLIENTS) {
                        // Add to clients collection
                        await db.collection("clients").doc(client.id).set(client);
                        
                        // Register corresponding auth credential
                        const email = `${client.username}@shirajlife.com`;
                        const secondaryApp = firebase.initializeApp(firebaseConfig, `SeedApp_${client.id}`);
                        try {
                            const userCredential = await secondaryApp.auth().createUserWithEmailAndPassword(email, client.password);
                            const uid = userCredential.user.uid;

                            await db.collection("users").doc(uid).set({
                                email: email,
                                role: "client",
                                clientId: client.id,
                                name: client.name
                            });
                            await secondaryApp.auth().signOut();
                        } catch (authErr) {
                            console.warn(`Auth credential seeding skipped for ${email} (might already exist):`, authErr);
                        } finally {
                            await secondaryApp.delete();
                        }
                    }
                    console.log("Database seeded successfully.");
                }
            } catch (e) {
                console.error("Error seeding default data:", e);
            }
        }
    };

    // 5. FIRESTORE DATABASE SYNCHRONIZER
    // If Firebase is initialized, start database listeners to sync cache and dispatch events
    if (ShirajAuth.isFirebase) {
        const db = firebase.firestore();
        const auth = firebase.auth();

        // Check if there is already a cached login token
        auth.onAuthStateChanged(async (user) => {
            const currentSession = ShirajAuth.getCurrentUser();
            if (user) {
                // If Firebase has a user but local storage is blank, fetch user record and write cache
                if (!currentSession || currentSession.uid !== user.uid) {
                    try {
                        const userDoc = await db.collection("users").doc(user.uid).get();
                        if (userDoc.exists) {
                            const uData = userDoc.data();
                            const sessionUser = {
                                uid: user.uid,
                                username: user.email.split("@")[0],
                                email: user.email,
                                role: uData.role,
                                name: uData.name || (uData.role === "admin" ? "Shiraj (Admin)" : "Client"),
                                clientId: uData.clientId || null
                            };
                            localStorage.setItem("shiraj_auth_user", JSON.stringify(sessionUser));
                            window.dispatchEvent(new Event("storage"));
                        }
                    } catch (e) {
                        console.error("Failed to sync auth state on change:", e);
                    }
                }
            } else {
                // If Firebase is signed out, clear local cache
                if (currentSession) {
                    localStorage.removeItem("shiraj_auth_user");
                    window.dispatchEvent(new Event("storage"));
                }
            }
        });

        // Set up real-time listener for client records
        db.collection("clients").onSnapshot((snapshot) => {
            const clientsList = [];
            snapshot.forEach(doc => {
                clientsList.push(doc.data());
            });
            // Update local storage cache and trigger page re-renders
            localStorage.setItem("shiraj_clients_data", JSON.stringify(clientsList));
            window.dispatchEvent(new Event("storage"));
        }, (error) => {
            console.error("Firestore Clients listener failed:", error);
        });
    }

    // 6. HEADER NAVIGATION DYNAMIC INITIALIZATION
    window.updateHeaderAuth = function () {
        const user = ShirajAuth.getCurrentUser();
        const headerPortalBtn = document.getElementById("header-portal-btn");
        if (headerPortalBtn) {
            if (user) {
                headerPortalBtn.textContent = "Dashboard";
                headerPortalBtn.href = user.role === "admin" ? "admin-dashboard.html" : "client-dashboard.html";
                headerPortalBtn.classList.remove("btn-secondary");
                headerPortalBtn.classList.add("btn-primary");
            } else {
                headerPortalBtn.textContent = "Client Portal";
                headerPortalBtn.href = "login.html";
                headerPortalBtn.classList.remove("btn-primary");
                headerPortalBtn.classList.add("btn-secondary");
            }
        }

        // Handle mobile drawer link if exists
        const mobileDrawer = document.getElementById("mobile-drawer");
        if (mobileDrawer) {
            let mobilePortalLink = document.getElementById("mobile-portal-link");
            if (!mobilePortalLink) {
                mobilePortalLink = document.createElement("a");
                mobilePortalLink.id = "mobile-portal-link";
                mobilePortalLink.className = "nav-link";
                mobileDrawer.appendChild(mobilePortalLink);
            }
            if (user) {
                mobilePortalLink.textContent = "Dashboard";
                mobilePortalLink.href = user.role === "admin" ? "admin-dashboard.html" : "client-dashboard.html";
            } else {
                mobilePortalLink.textContent = "Client Portal";
                mobilePortalLink.href = "login.html";
            }
        }
    };

    // Custom Slide-In Toast Notification System
    window.showToast = function (message, type = "success") {
        let container = document.getElementById("toast-container");
        if (!container) {
            container = document.createElement("div");
            container.id = "toast-container";
            container.className = "toast-container";
            document.body.appendChild(container);
        }

        const toast = document.createElement("div");
        toast.className = `toast ${type}`;
        toast.innerHTML = `<span class="toast-text">${message}</span>`;
        container.appendChild(toast);

        // Slide in
        setTimeout(() => {
            toast.classList.add("show");
        }, 10);

        // Auto remove after 3.5 seconds
        setTimeout(() => {
            toast.classList.remove("show");
            setTimeout(() => {
                toast.remove();
            }, 400);
        }, 3500);
    };

    // Run immediately when loaded
    document.addEventListener("DOMContentLoaded", () => {
        window.updateHeaderAuth();
    });
})();
