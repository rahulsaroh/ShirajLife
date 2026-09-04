/**
 * Shiraj Life - Unified Web Portal View Renderers
 */

const PortalViews = {

    // --- Formatters ---
    formatINR(num) {
        return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(num || 0);
    },

    formatUSD(num) {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(num || 0);
    },

    // ==========================================
    // 1. LAUNCHPAD / OVERVIEW VIEW
    // ==========================================
    renderOverview(state) {
        const clients = state.clients || [];
        const totalValue = clients.reduce((sum, c) => sum + (c.totalValue || 0), 0);
        const totalPaid = clients.reduce((sum, c) => sum + (c.amountPaid || 0), 0);
        const membersCount = (state.gym && state.gym.members ? state.gym.members.length : 142);

        return `
            <div class="view-header">
                <div class="view-title-group">
                    <h1>Portal Launchpad</h1>
                    <p>Central operations command center for client deliverables, gym SaaS, and BI tools.</p>
                </div>
                <div class="view-actions">
                    <span class="p-badge p-badge-teal">● System Live</span>
                    <button class="p-btn p-btn-secondary" onclick="PortalApp.refreshData()">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 4v6h-6M1 20v-6h6"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
                        Sync Data
                    </button>
                </div>
            </div>

            <div class="p-metrics-grid">
                <div class="p-metric-card">
                    <div class="p-metric-top">
                        <span class="p-metric-label">B2B Contract Revenue</span>
                        <div class="p-metric-icon">₹</div>
                    </div>
                    <div class="p-metric-val">${this.formatINR(totalPaid)}</div>
                    <div class="p-metric-sub"><span class="p-trend-up">↑ 100%</span> of billed milestones collected</div>
                </div>

                <div class="p-metric-card">
                    <div class="p-metric-top">
                        <span class="p-metric-label">Active Client Projects</span>
                        <div class="p-metric-icon">⚡</div>
                    </div>
                    <div class="p-metric-val">${clients.length}</div>
                    <div class="p-metric-sub">${clients.filter(c => c.status === 'Active').length} active delivery pipelines</div>
                </div>

                <div class="p-metric-card">
                    <div class="p-metric-top">
                        <span class="p-metric-label">goJim SaaS Members</span>
                        <div class="p-metric-icon">🏋️</div>
                    </div>
                    <div class="p-metric-val">${membersCount}</div>
                    <div class="p-metric-sub"><span class="p-trend-up">↑ 94.2%</span> monthly retention rate</div>
                </div>

                <div class="p-metric-card">
                    <div class="p-metric-top">
                        <span class="p-metric-label">Interactive BI Suite</span>
                        <div class="p-metric-icon">📊</div>
                    </div>
                    <div class="p-metric-val">3 Engines</div>
                    <div class="p-metric-sub">Real Estate, Runway, CRM Funnels</div>
                </div>
            </div>

            <div class="p-card-header" style="margin-top: 1rem;">
                <h2>Platform Workspaces & Tools</h2>
            </div>

            <div class="p-launchpad-grid">
                <a href="#/admin" class="p-launch-card">
                    <span class="p-launch-card-badge">B2B Agency</span>
                    <div class="p-launch-icon-wrap">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                    </div>
                    <div>
                        <h3>Admin Agency Console</h3>
                        <p>Manage client contracts, milestone delivery pipelines, live client messaging inbox, and credential provisioning.</p>
                    </div>
                    <div class="p-launch-card-footer">
                        <span>Launch Console</span> →
                    </div>
                </a>

                <a href="#/client" class="p-launch-card">
                    <span class="p-launch-card-badge">Client Portal</span>
                    <div class="p-launch-icon-wrap">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                    </div>
                    <div>
                        <h3>Client Project Hub</h3>
                        <p>Real-time client view for milestone progress, balance due, developer feedback streams, and deliverables review.</p>
                    </div>
                    <div class="p-launch-card-footer">
                        <span>Open Workspace</span> →
                    </div>
                </a>

                <a href="#/gym" class="p-launch-card">
                    <span class="p-launch-card-badge">SaaS Operating System</span>
                    <div class="p-launch-icon-wrap">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8h1a4 4 0 0 1 0 8h-1M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"/></svg>
                    </div>
                    <div>
                        <h3>goJim Gym SaaS</h3>
                        <p>Complete multi-role platform: Live capacity heatmaps, POS pro-shop, leads CRM, trainer booking, and student PR charts.</p>
                    </div>
                    <div class="p-launch-card-footer">
                        <span>Launch goJim</span> →
                    </div>
                </a>

                <a href="#/tools/spreadsheets" class="p-launch-card">
                    <span class="p-launch-card-badge">BI & Analytics</span>
                    <div class="p-launch-icon-wrap">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
                    </div>
                    <div>
                        <h3>Spreadsheet & Underwriter Suite</h3>
                        <p>Interactive mathematical engines for Real Estate cashflow, SaaS runway forecasting, and sales commission pipelines.</p>
                    </div>
                    <div class="p-launch-card-footer">
                        <span>Open Calculators</span> →
                    </div>
                </a>

                <a href="#/tools/finance" class="p-launch-card">
                    <span class="p-launch-card-badge">FinTech</span>
                    <div class="p-launch-icon-wrap">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 1v22M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
                    </div>
                    <div>
                        <h3>AI Finance Manager</h3>
                        <p>Offline CAS statement parser, portfolio asset rebalancer, and capital gains tax optimization architecture.</p>
                    </div>
                    <div class="p-launch-card-footer">
                        <span>View Architecture</span> →
                    </div>
                </a>

                <a href="#/showcases/ironpulse" class="p-launch-card">
                    <span class="p-launch-card-badge">Client Showcase</span>
                    <div class="p-launch-icon-wrap">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="m10 15 5-3-5-3v6z"/></svg>
                    </div>
                    <div>
                        <h3>IronPulse Gym Demo</h3>
                        <p>Client landing page with interactive multi-duration membership pricing calculator and facility preview.</p>
                    </div>
                    <div class="p-launch-card-footer">
                        <span>Open Showcase</span> →
                    </div>
                </a>
            </div>
        `;
    },

    // ==========================================
    // 2. ADMIN CRM CONSOLE
    // ==========================================
    renderAdmin(state) {
        const clients = state.clients || [];
        const totalVal = clients.reduce((sum, c) => sum + (c.totalValue || 0), 0);
        const totalPaid = clients.reduce((sum, c) => sum + (c.amountPaid || 0), 0);
        const totalDue = totalVal - totalPaid;

        return `
            <div class="view-header">
                <div class="view-title-group">
                    <h1>Admin Agency Console</h1>
                    <p>Manage freelance client deliverables, payment receipts, and customer portals.</p>
                </div>
                <div class="view-actions">
                    <button class="p-btn p-btn-primary" onclick="PortalApp.openAddClientModal()">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                        Add New Client
                    </button>
                </div>
            </div>

            <div class="p-metrics-grid">
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">Total Contract Value</span><div class="p-metric-icon">💼</div></div>
                    <div class="p-metric-val">${this.formatINR(totalVal)}</div>
                    <div class="p-metric-sub">${clients.length} active client accounts</div>
                </div>
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">Revenue Collected</span><div class="p-metric-icon">💰</div></div>
                    <div class="p-metric-val">${this.formatINR(totalPaid)}</div>
                    <div class="p-metric-sub"><span class="p-trend-up">↑ Paid in full</span> on completed milestones</div>
                </div>
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">Outstanding Balance</span><div class="p-metric-icon">⏳</div></div>
                    <div class="p-metric-val">${this.formatINR(totalDue)}</div>
                    <div class="p-metric-sub">Pending delivery sign-off</div>
                </div>
            </div>

            <div class="p-card">
                <div class="p-card-header">
                    <h3>Client Portals & Contract Ledger</h3>
                    <input type="text" id="admin-client-search" class="p-input" style="max-width: 240px; padding: 0.4rem 0.75rem; font-size: 0.82rem;" placeholder="Search client or service..." oninput="PortalApp.filterAdminClients(this.value)">
                </div>
                <div class="p-table-responsive">
                    <table class="p-table" id="admin-clients-table">
                        <thead>
                            <tr>
                                <th>Client Name</th>
                                <th>Service Scope</th>
                                <th>Contract (INR)</th>
                                <th>Balance Due</th>
                                <th>Progress</th>
                                <th>Status</th>
                                <th style="text-align: right;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${clients.map(c => `
                                <tr>
                                    <td>
                                        <div style="font-weight: 700; color: var(--txt-0);">${c.name}</div>
                                        <div style="font-size: 0.75rem; color: var(--txt-2); font-family: var(--font-mono);">${c.username || c.id}</div>
                                    </td>
                                    <td>${c.service}</td>
                                    <td style="font-family: var(--font-mono); font-weight: 600;">${this.formatINR(c.totalValue)}</td>
                                    <td style="font-family: var(--font-mono); color: ${c.balanceDue > 0 ? '#f59e0b' : '#10b981'};">${this.formatINR(c.balanceDue || (c.totalValue - c.amountPaid))}</td>
                                    <td>
                                        <div style="display: flex; align-items: center; gap: 0.5rem;">
                                            <div style="flex: 1; height: 6px; background: var(--bg-2); border-radius: 3px; overflow: hidden; min-width: 60px;">
                                                <div style="width: ${c.progress || 0}%; height: 100%; background: var(--acc); border-radius: 3px;"></div>
                                            </div>
                                            <span style="font-family: var(--font-mono); font-size: 0.75rem; min-width: 32px;">${c.progress || 0}%</span>
                                        </div>
                                    </td>
                                    <td>
                                        <span class="p-badge ${c.status === 'Active' ? 'p-badge-active' : 'p-badge-pending'}">${c.status}</span>
                                    </td>
                                    <td style="text-align: right;">
                                        <a href="#/client?preview=${c.id}" class="p-btn p-btn-secondary p-btn-sm" style="margin-right: 0.25rem;">Preview Portal</a>
                                        <button class="p-btn p-btn-secondary p-btn-sm" onclick="PortalApp.openEditClientModal('${c.id}')">Edit</button>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="p-card">
                <div class="p-card-header">
                    <h3>Client Feedback & Messages Stream</h3>
                </div>
                <div style="display: flex; flex-direction: column; gap: 1rem;">
                    <div style="padding: 1rem; background: var(--bg-1); border-radius: 12px; border-left: 3px solid var(--acc);">
                        <div style="display: flex; justify-content: space-between; margin-bottom: 0.35rem;">
                            <strong style="color: var(--txt-0); font-size: 0.88rem;">Ritu Designer Wear</strong>
                            <span style="font-size: 0.75rem; color: var(--txt-2); font-family: var(--font-mono);">Today, 14:20</span>
                        </div>
                        <p style="margin: 0 0 0.5rem 0; font-size: 0.85rem; color: var(--txt-1);">"The bridal gallery filtering is fantastic! Ready for the payment gateway integration on staging."</p>
                        <button class="p-btn p-btn-secondary p-btn-sm" onclick="PortalApp.showQuickReply('Ritu Designer Wear')">Send Reply</button>
                    </div>

                    <div style="padding: 1rem; background: var(--bg-1); border-radius: 12px; border-left: 3px solid var(--acc);">
                        <div style="display: flex; justify-content: space-between; margin-bottom: 0.35rem;">
                            <strong style="color: var(--txt-0); font-size: 0.88rem;">IronPulse Gym & Fitness</strong>
                            <span style="font-size: 0.75rem; color: var(--txt-2); font-family: var(--font-mono);">Yesterday</span>
                        </div>
                        <p style="margin: 0 0 0.5rem 0; font-size: 0.85rem; color: var(--txt-1);">"Reviewed the new QR Turnstile check-in flow. Everything looks great for the branch launch."</p>
                        <button class="p-btn p-btn-secondary p-btn-sm" onclick="PortalApp.showQuickReply('IronPulse Gym & Fitness')">Send Reply</button>
                    </div>
                </div>
            </div>
        `;
    },

    // ==========================================
    // 3. CLIENT PROJECT PORTAL VIEW
    // ==========================================
    renderClient(state, previewId) {
        const clients = state.clients || [];
        const client = clients.find(c => c.id === previewId) || clients[0] || {
            name: "Ritu Designer Wear",
            service: "High-Fashion E-Commerce & Bridal Portfolio",
            totalValue: 85000,
            amountPaid: 85000,
            progress: 100,
            status: "Completed",
            renewalDate: "2026-12-01",
            overview: "Bespoke digital storefront and bridal appointment booking platform with cloud assets.",
            milestones: [
                { step: 1, title: "Brand Discovery & Wireframes", desc: "Design system architecture and UX moodboards.", completed: true },
                { step: 2, title: "High-Fashion UI Prototype", desc: "Interactive mobile and desktop Figma prototypes.", completed: true },
                { step: 3, title: "Custom Responsive Web Build", desc: "Semantic HTML5, CSS animations, and performance optimization.", completed: true },
                { step: 4, title: "Client Portal & Payment Gateway", desc: "Secure Razorpay / Stripe checkout workflow.", completed: true },
                { step: 5, title: "Live Deployment & Handover", desc: "Cloudflare Pages DNS setup and staff CMS guide.", completed: true }
            ]
        };

        const milestones = client.milestones || [
            { step: 1, title: "Requirements & System Architecture", desc: "Scope definition, database schema, and interface design.", completed: true },
            { step: 2, title: "Core MVP Development", desc: "Frontend components, responsive styling, and mock state.", completed: true },
            { step: 3, title: "Cloud Backend & Authentication", desc: "Firestore collections, security rules, and user roles.", completed: client.progress >= 60 },
            { step: 4, title: "Interactive BI & Integrations", desc: "Chart.js analytics, Stripe webhook billing, and QR scan.", completed: client.progress >= 85 },
            { step: 5, title: "Final Production Deployment", desc: "Domain verification, CDN caching, and sign-off.", completed: client.progress >= 100 }
        ];

        return `
            <div class="view-header">
                <div class="view-title-group">
                    <div style="display: flex; align-items: center; gap: 0.75rem; margin-bottom: 0.25rem;">
                        <h1>${client.name}</h1>
                        <span class="p-badge ${client.status === 'Completed' ? 'p-badge-active' : 'p-badge-pending'}">${client.status}</span>
                    </div>
                    <p>${client.service}</p>
                </div>
                <div class="view-actions">
                    <a href="#/admin" class="p-btn p-btn-secondary p-btn-sm">Switch Client View</a>
                    <button class="p-btn p-btn-primary p-btn-sm" onclick="PortalApp.toast('Deliverables downloaded.')">Download Invoices</button>
                </div>
            </div>

            <div class="p-metrics-grid">
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">Contract Value</span><div class="p-metric-icon">📜</div></div>
                    <div class="p-metric-val">${this.formatINR(client.totalValue)}</div>
                    <div class="p-metric-sub">Agreed milestone scope</div>
                </div>
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">Amount Paid</span><div class="p-metric-icon">💳</div></div>
                    <div class="p-metric-val">${this.formatINR(client.amountPaid)}</div>
                    <div class="p-metric-sub"><span class="p-trend-up">Verified</span> via bank / Stripe</div>
                </div>
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">Balance Due</span><div class="p-metric-icon">⌛</div></div>
                    <div class="p-metric-val">${this.formatINR((client.totalValue || 0) - (client.amountPaid || 0))}</div>
                    <div class="p-metric-sub">Renewal: ${client.renewalDate || 'Dec 2026'}</div>
                </div>
            </div>

            <div class="p-card">
                <div class="p-card-header">
                    <h3>Project Delivery Pipeline (${client.progress || 0}% Complete)</h3>
                </div>
                <div style="width: 100%; height: 8px; background: var(--bg-2); border-radius: 4px; overflow: hidden; margin-bottom: 1.5rem;">
                    <div style="width: ${client.progress || 0}%; height: 100%; background: linear-gradient(90deg, var(--acc), var(--acc-br)); border-radius: 4px;"></div>
                </div>

                <div class="p-stepper">
                    ${milestones.map((m, idx) => `
                        <div class="p-step-item ${m.completed ? 'completed' : (idx === 0 || milestones[idx - 1]?.completed ? 'active' : '')}">
                            <div class="p-step-circle">${m.completed ? '✓' : m.step}</div>
                            <div class="p-step-content">
                                <div class="p-step-title">${m.title}</div>
                                <div class="p-step-desc">${m.desc}</div>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>

            <div class="p-card">
                <div class="p-card-header">
                    <h3>Developer Status Stream & Feedback</h3>
                </div>
                <div style="background: var(--bg-1); border-radius: 12px; padding: 1.25rem; margin-bottom: 1rem;">
                    <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
                        <span style="font-weight: 700; color: var(--txt-0);">Shiraj (Lead Developer)</span>
                        <span style="font-size: 0.75rem; color: var(--txt-2); font-family: var(--font-mono);">2 days ago</span>
                    </div>
                    <p style="margin: 0; font-size: 0.88rem; color: var(--txt-1); line-height: 1.5;">
                        Milestone 4 is complete! The interactive portal and billing webhooks have been verified against test environments. Production build deployed to Cloudflare CDN edge.
                    </p>
                </div>

                <div class="p-form-group" style="margin-bottom: 0;">
                    <label class="p-form-label">Send Message to Developer</label>
                    <div style="display: flex; gap: 0.75rem;">
                        <input type="text" id="client-msg-input" class="p-input" placeholder="Type a comment or feedback...">
                        <button class="p-btn p-btn-primary" onclick="PortalApp.sendClientMessage()">Send</button>
                    </div>
                </div>
            </div>
        `;
    },

    // ==========================================
    // 4. goJim MULTI-ROLE GYM MANAGEMENT SAAS
    // ==========================================
    renderGym(state, subRole = 'owner') {
        const gym = state.gym || {};
        const members = gym.members || [];
        const equipment = gym.equipment || [];

        return `
            <div class="view-header">
                <div class="view-title-group">
                    <div style="display: flex; align-items: center; gap: 0.75rem; margin-bottom: 0.25rem;">
                        <h1>goJim Management Suite</h1>
                        <span class="p-badge p-badge-teal">IronPulse Fitness Co.</span>
                    </div>
                    <p>Multi-role fitness operations, capacity heatmaps, trainer rosters, and student workout tracking.</p>
                </div>
                <div class="view-actions">
                    <div class="p-tabs" style="margin: 0; border: none;">
                        <button class="p-tab-btn ${subRole === 'owner' ? 'active' : ''}" onclick="PortalApp.navigate('gym/owner')">Owner View</button>
                        <button class="p-tab-btn ${subRole === 'trainer' ? 'active' : ''}" onclick="PortalApp.navigate('gym/trainer')">Trainer View</button>
                        <button class="p-tab-btn ${subRole === 'student' ? 'active' : ''}" onclick="PortalApp.navigate('gym/student')">Member Pass</button>
                    </div>
                </div>
            </div>

            ${subRole === 'owner' ? this.renderGymOwnerSubView(gym) : ''}
            ${subRole === 'trainer' ? this.renderGymTrainerSubView(gym) : ''}
            ${subRole === 'student' ? this.renderGymStudentSubView(gym) : ''}
        `;
    },

    renderGymOwnerSubView(gym) {
        return `
            <div class="p-metrics-grid">
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">Monthly Recurring Revenue</span><div class="p-metric-icon">₹</div></div>
                    <div class="p-metric-val">₹2,84,000</div>
                    <div class="p-metric-sub"><span class="p-trend-up">↑ 14.8%</span> vs previous month</div>
                </div>
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">Active Roster</span><div class="p-metric-icon">👥</div></div>
                    <div class="p-metric-val">142 Members</div>
                    <div class="p-metric-sub">8 Elite Personal Trainers</div>
                </div>
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">Floor Occupancy</span><div class="p-metric-icon">🔥</div></div>
                    <div class="p-metric-val" id="gym-occupancy-count">21 / 32</div>
                    <div class="p-metric-sub">Peak operating capacity (65%)</div>
                </div>
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">SaaS License Status</span><div class="p-metric-icon">🛡️</div></div>
                    <div class="p-metric-val" style="color: #10b981; font-size: 1.4rem;">Stripe Active</div>
                    <div class="p-metric-sub">Sub ID: sub_ironpulse_live</div>
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem;" class="p-grid-2col">
                <div class="p-card">
                    <div class="p-card-header">
                        <h3>Live Gym Floor Capacity (32 Stations)</h3>
                        <button class="p-btn p-btn-secondary p-btn-sm" onclick="PortalApp.simulateCheckIn()">Simulate Check-In</button>
                    </div>
                    <p style="font-size: 0.85rem; color: var(--txt-2); margin-top: -0.5rem; margin-bottom: 1rem;">
                        Real-time RFID/QR turnstile status across cardio deck, power racks, and dumbbells.
                    </p>
                    <div class="p-heatmap-grid" id="gym-heatmap">
                        ${Array.from({ length: 32 }).map((_, i) => `
                            <div class="p-heatmap-cell ${i < 21 ? 'occupied' : ''}">#${i + 1}</div>
                        `).join('')}
                    </div>
                </div>

                <div class="p-card">
                    <div class="p-card-header">
                        <h3>Pro-Shop POS Express Terminal</h3>
                        <span class="p-badge p-badge-teal" id="pos-cart-badge">Cart: ₹0</span>
                    </div>
                    <div style="display: flex; flex-direction: column; gap: 0.75rem;">
                        <div style="display: flex; align-items: center; justify-content: space-between; padding: 0.6rem; background: var(--bg-1); border-radius: 8px;">
                            <div>
                                <div style="font-weight: 600; font-size: 0.88rem; color: var(--txt-0);">Gold Standard Whey (2kg)</div>
                                <div style="font-size: 0.75rem; color: var(--txt-2);">₹5,400 • In Stock (18)</div>
                            </div>
                            <button class="p-btn p-btn-secondary p-btn-sm" onclick="PortalApp.addToPosCart(5400, 'Whey')">+ Add</button>
                        </div>
                        <div style="display: flex; align-items: center; justify-content: space-between; padding: 0.6rem; background: var(--bg-1); border-radius: 8px;">
                            <div>
                                <div style="font-weight: 600; font-size: 0.88rem; color: var(--txt-0);">BCAA 2:1:1 Watermelon</div>
                                <div style="font-size: 0.75rem; color: var(--txt-2);">₹1,850 • In Stock (34)</div>
                            </div>
                            <button class="p-btn p-btn-secondary p-btn-sm" onclick="PortalApp.addToPosCart(1850, 'BCAA')">+ Add</button>
                        </div>
                        <div style="display: flex; align-items: center; justify-content: space-between; padding: 0.6rem; background: var(--bg-1); border-radius: 8px;">
                            <div>
                                <div style="font-weight: 600; font-size: 0.88rem; color: var(--txt-0);">Heavy Duty Lifting Straps</div>
                                <div style="font-size: 0.75rem; color: var(--txt-2);">₹650 • In Stock (50)</div>
                            </div>
                            <button class="p-btn p-btn-secondary p-btn-sm" onclick="PortalApp.addToPosCart(650, 'Straps')">+ Add</button>
                        </div>
                    </div>
                    <div style="margin-top: 1rem; display: flex; justify-content: flex-end;">
                        <button class="p-btn p-btn-primary p-btn-sm" onclick="PortalApp.posCheckout()">Charge Member Account</button>
                    </div>
                </div>
            </div>

            <div class="p-card">
                <div class="p-card-header">
                    <h3>Machinery & Equipment Health Registry</h3>
                    <button class="p-btn p-btn-secondary p-btn-sm" onclick="PortalApp.openTicketModal()">+ Report Ticket</button>
                </div>
                <div class="p-table-responsive">
                    <table class="p-table">
                        <thead>
                            <tr>
                                <th>Asset ID</th>
                                <th>Machine / Station</th>
                                <th>Zone</th>
                                <th>Last Service</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td style="font-family: var(--font-mono);">#EQ-01</td>
                                <td>Eleiko Olympic Power Rack #1</td>
                                <td>Powerlifting Zone</td>
                                <td>2026-08-15</td>
                                <td><span class="p-badge p-badge-active">Operational</span></td>
                            </tr>
                            <tr>
                                <td style="font-family: var(--font-mono);">#EQ-04</td>
                                <td>Concept2 RowErg PM5</td>
                                <td>Cardio Loft</td>
                                <td>2026-07-28</td>
                                <td><span class="p-badge p-badge-active">Operational</span></td>
                            </tr>
                            <tr>
                                <td style="font-family: var(--font-mono);">#EQ-08</td>
                                <td>Dual Adjustable Cable Column</td>
                                <td>Main Strength</td>
                                <td>2026-08-30</td>
                                <td><span class="p-badge p-badge-pending">Service Due</span></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        `;
    },

    renderGymTrainerSubView(gym) {
        return `
            <div class="p-card">
                <div class="p-card-header">
                    <h3>Trainer Roster & Assigned Athletes (Coach Rahul)</h3>
                </div>
                <div class="p-table-responsive">
                    <table class="p-table">
                        <thead>
                            <tr>
                                <th>Athlete Name</th>
                                <th>Active Split</th>
                                <th>Squat 1RM</th>
                                <th>Bench 1RM</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td><strong>Aman Sharma</strong></td>
                                <td>Push/Pull/Legs Hypertrophy</td>
                                <td style="font-family: var(--font-mono);">140 kg</td>
                                <td style="font-family: var(--font-mono);">105 kg</td>
                                <td><button class="p-btn p-btn-secondary p-btn-sm" onclick="PortalApp.toast('Form feedback sent to Aman.')">Log Feedback</button></td>
                            </tr>
                            <tr>
                                <td><strong>Pooja Mehta</strong></td>
                                <td>Metabolic Conditioning</td>
                                <td style="font-family: var(--font-mono);">85 kg</td>
                                <td style="font-family: var(--font-mono);">52.5 kg</td>
                                <td><button class="p-btn p-btn-secondary p-btn-sm" onclick="PortalApp.toast('Form feedback sent to Pooja.')">Log Feedback</button></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        `;
    },

    renderGymStudentSubView(gym) {
        return `
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem;" class="p-grid-2col">
                <div class="p-card" style="text-align: center; padding: 2rem;">
                    <div style="width: 140px; height: 140px; margin: 0 auto 1.5rem; background: var(--bg-1); border: 2px dashed var(--acc); border-radius: 16px; display: flex; align-items: center; justify-content: center;">
                        <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>
                    </div>
                    <h3 style="margin: 0 0 0.25rem 0;">Aman Sharma</h3>
                    <p style="color: var(--txt-2); font-family: var(--font-mono); font-size: 0.85rem; margin-bottom: 1.25rem;">Member ID: #IP-9842 • Tier: Elite Access</p>
                    <button class="p-btn p-btn-primary" onclick="PortalApp.toast('Turnstile QR Scanned! Check-in Confirmed.')">Simulate Turnstile Scan</button>
                </div>

                <div class="p-card">
                    <div class="p-card-header">
                        <h3>Today's Training Split: Upper Power</h3>
                    </div>
                    <div style="display: flex; flex-direction: column; gap: 0.75rem;">
                        <label style="display: flex; align-items: center; gap: 0.75rem; padding: 0.5rem; background: var(--bg-1); border-radius: 8px; cursor: pointer;">
                            <input type="checkbox" checked style="accent-color: var(--acc);">
                            <span>Barbell Incline Bench Press (4x6 @ 90kg)</span>
                        </label>
                        <label style="display: flex; align-items: center; gap: 0.75rem; padding: 0.5rem; background: var(--bg-1); border-radius: 8px; cursor: pointer;">
                            <input type="checkbox" checked style="accent-color: var(--acc);">
                            <span>Weighted Pull-Ups (4x8 @ +15kg)</span>
                        </label>
                        <label style="display: flex; align-items: center; gap: 0.75rem; padding: 0.5rem; background: var(--bg-1); border-radius: 8px; cursor: pointer;">
                            <input type="checkbox" style="accent-color: var(--acc);">
                            <span>Standing Overhead Press (3x8 @ 60kg)</span>
                        </label>
                    </div>
                </div>
            </div>
        `;
    },

    // ==========================================
    // 5. INTERACTIVE BI & SPREADSHEET ENGINES
    // ==========================================
    renderSpreadsheets(state) {
        return `
            <div class="view-header">
                <div class="view-title-group">
                    <h1>Interactive BI & Spreadsheet Engines</h1>
                    <p>Live mathematical underwriting, business cashflow models, and SaaS growth forecasting.</p>
                </div>
                <div class="view-actions">
                    <div class="p-tabs" style="margin: 0; border: none;">
                        <button class="p-tab-btn active" id="btn-tab-re" onclick="PortalApp.switchBiTab('re')">Real Estate Deal</button>
                        <button class="p-tab-btn" id="btn-tab-saas" onclick="PortalApp.switchBiTab('saas')">Runway & P&L</button>
                        <button class="p-tab-btn" id="btn-tab-sales" onclick="PortalApp.switchBiTab('sales')">Sales Pipeline</button>
                    </div>
                </div>
            </div>

            <!-- Tab 1: Real Estate Cashflow -->
            <div id="bi-tab-re-panel">
                <div style="display: grid; grid-template-columns: 1fr 1.2fr; gap: 1.5rem;" class="p-grid-2col">
                    <div class="p-card">
                        <div class="p-card-header">
                            <h3>Deal Parameters</h3>
                            <span class="p-badge p-badge-teal">Underwriter v2</span>
                        </div>
                        <div class="p-slider-group">
                            <div class="p-slider-header"><span>Purchase Price</span><span class="p-slider-val" id="re-val-price">$350,000</span></div>
                            <input type="range" class="p-range-input" min="100000" max="1500000" step="10000" value="350000" id="re-in-price" oninput="PortalApp.runRealEstateCalc()">
                        </div>
                        <div class="p-slider-group">
                            <div class="p-slider-header"><span>Down Payment (%)</span><span class="p-slider-val" id="re-val-down">20%</span></div>
                            <input type="range" class="p-range-input" min="5" max="50" step="5" value="20" id="re-in-down" oninput="PortalApp.runRealEstateCalc()">
                        </div>
                        <div class="p-slider-group">
                            <div class="p-slider-header"><span>Mortgage Rate (%)</span><span class="p-slider-val" id="re-val-rate">6.5%</span></div>
                            <input type="range" class="p-range-input" min="3.0" max="10.0" step="0.1" value="6.5" id="re-in-rate" oninput="PortalApp.runRealEstateCalc()">
                        </div>
                        <div class="p-slider-group">
                            <div class="p-slider-header"><span>Monthly Gross Rent</span><span class="p-slider-val" id="re-val-rent">$3,200</span></div>
                            <input type="range" class="p-range-input" min="1000" max="12000" step="100" value="3200" id="re-in-rent" oninput="PortalApp.runRealEstateCalc()">
                        </div>
                    </div>

                    <div class="p-card">
                        <div class="p-card-header">
                            <h3>Returns & Cashflow Breakdown</h3>
                            <span class="p-verdict p-verdict-strong" id="re-verdict">STRONG DEAL</span>
                        </div>
                        <div class="p-metrics-grid" style="grid-template-columns: 1fr 1fr; margin-bottom: 1rem;">
                            <div>
                                <div class="p-metric-label">Monthly Net Cashflow</div>
                                <div class="p-metric-val" id="re-out-cashflow" style="font-size: 1.5rem; color: #10b981;">+$682</div>
                            </div>
                            <div>
                                <div class="p-metric-label">Cap Rate</div>
                                <div class="p-metric-val" id="re-out-cap" style="font-size: 1.5rem;">7.8%</div>
                            </div>
                        </div>
                        <div style="position: relative; height: 220px; width: 100%;">
                            <canvas id="re-chart-canvas"></canvas>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tab 2: SaaS Runway & P&L -->
            <div id="bi-tab-saas-panel" style="display: none;">
                <div style="display: grid; grid-template-columns: 1fr 1.2fr; gap: 1.5rem;" class="p-grid-2col">
                    <div class="p-card">
                        <div class="p-card-header">
                            <h3>Business P&L Inputs</h3>
                        </div>
                        <div class="p-slider-group">
                            <div class="p-slider-header"><span>Cash Reserves</span><span class="p-slider-val" id="saas-val-reserves">$120,000</span></div>
                            <input type="range" class="p-range-input" min="10000" max="500000" step="5000" value="120000" id="saas-in-reserves" oninput="PortalApp.runSaasCalc()">
                        </div>
                        <div class="p-slider-group">
                            <div class="p-slider-header"><span>Current MRR</span><span class="p-slider-val" id="saas-val-mrr">$18,000</span></div>
                            <input type="range" class="p-range-input" min="1000" max="100000" step="1000" value="18000" id="saas-in-mrr" oninput="PortalApp.runSaasCalc()">
                        </div>
                        <div class="p-slider-group">
                            <div class="p-slider-header"><span>Monthly Burn / OpEx</span><span class="p-slider-val" id="saas-val-burn">$14,500</span></div>
                            <input type="range" class="p-range-input" min="2000" max="80000" step="500" value="14500" id="saas-in-burn" oninput="PortalApp.runSaasCalc()">
                        </div>
                    </div>

                    <div class="p-card">
                        <div class="p-card-header">
                            <h3>Runway & Forecast</h3>
                            <span class="p-verdict p-verdict-strong" id="saas-verdict">PROFITABLE</span>
                        </div>
                        <div class="p-metrics-grid" style="grid-template-columns: 1fr 1fr; margin-bottom: 1rem;">
                            <div>
                                <div class="p-metric-label">Monthly Net Margin</div>
                                <div class="p-metric-val" id="saas-out-margin" style="font-size: 1.5rem; color: #10b981;">+$3,500</div>
                            </div>
                            <div>
                                <div class="p-metric-label">Estimated ARR</div>
                                <div class="p-metric-val" id="saas-out-arr" style="font-size: 1.5rem;">$216,000</div>
                            </div>
                        </div>
                        <div style="position: relative; height: 220px; width: 100%;">
                            <canvas id="saas-chart-canvas"></canvas>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tab 3: Sales Pipeline -->
            <div id="bi-tab-sales-panel" style="display: none;">
                <div style="display: grid; grid-template-columns: 1fr 1.2fr; gap: 1.5rem;" class="p-grid-2col">
                    <div class="p-card">
                        <div class="p-card-header">
                            <h3>Pipeline Funnel</h3>
                        </div>
                        <div class="p-slider-group">
                            <div class="p-slider-header"><span>Inbound Leads</span><span class="p-slider-val" id="crm-val-leads">50</span></div>
                            <input type="range" class="p-range-input" min="10" max="500" step="10" value="50" id="crm-in-leads" oninput="PortalApp.runCrmCalc()">
                        </div>
                        <div class="p-slider-group">
                            <div class="p-slider-header"><span>Average Deal Size</span><span class="p-slider-val" id="crm-val-size">$4,500</span></div>
                            <input type="range" class="p-range-input" min="500" max="25000" step="500" value="4500" id="crm-in-size" oninput="PortalApp.runCrmCalc()">
                        </div>
                        <div class="p-slider-group">
                            <div class="p-slider-header"><span>Close Rate (%)</span><span class="p-slider-val" id="crm-val-rate">22%</span></div>
                            <input type="range" class="p-range-input" min="5" max="60" step="1" value="22" id="crm-in-rate" oninput="PortalApp.runCrmCalc()">
                        </div>
                    </div>

                    <div class="p-card">
                        <div class="p-card-header">
                            <h3>Revenue & Commission Forecast</h3>
                            <span class="p-verdict p-verdict-strong" id="crm-verdict">HIGH VELOCITY</span>
                        </div>
                        <div class="p-metrics-grid" style="grid-template-columns: 1fr 1fr; margin-bottom: 1rem;">
                            <div>
                                <div class="p-metric-label">Projected Revenue</div>
                                <div class="p-metric-val" id="crm-out-rev" style="font-size: 1.5rem; color: #10b981;">$49,500</div>
                            </div>
                            <div>
                                <div class="p-metric-label">Won Deals</div>
                                <div class="p-metric-val" id="crm-out-won" style="font-size: 1.5rem;">11 Deals</div>
                            </div>
                        </div>
                        <div style="position: relative; height: 220px; width: 100%;">
                            <canvas id="crm-chart-canvas"></canvas>
                        </div>
                    </div>
                </div>
            </div>
        `;
    },

    // ==========================================
    // 6. AI FINANCE MANAGER SHOWCASE
    // ==========================================
    renderFinance(state) {
        return `
            <div class="view-header">
                <div class="view-title-group">
                    <h1>AI Finance Manager & Wealth Parser</h1>
                    <p>Zero-cloud CAS PDF parser and capital gains tax optimization architecture for Indian retail investors.</p>
                </div>
                <div class="view-actions">
                    <span class="p-badge p-badge-active">Air-Gapped Security</span>
                </div>
            </div>

            <div class="p-metrics-grid">
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">Statement Parser</span><div class="p-metric-icon">📑</div></div>
                    <div class="p-metric-val">NSDL / CDSL</div>
                    <div class="p-metric-sub">Local regex & PyPDF extraction</div>
                </div>
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">Privacy Model</span><div class="p-metric-icon">🔒</div></div>
                    <div class="p-metric-val">100% Offline</div>
                    <div class="p-metric-sub">Zero network transmission of financial data</div>
                </div>
                <div class="p-metric-card">
                    <div class="p-metric-top"><span class="p-metric-label">Tax Engine</span><div class="p-metric-icon">⚖️</div></div>
                    <div class="p-metric-val">STCG & LTCG</div>
                    <div class="p-metric-sub">Automated grandfathering calculations</div>
                </div>
            </div>

            <div class="p-card">
                <div class="p-card-header">
                    <h3>Architectural Stack & Security Blueprint</h3>
                </div>
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1rem;">
                    <div style="padding: 1.25rem; background: var(--bg-1); border-radius: 12px;">
                        <h4 style="margin: 0 0 0.5rem 0; color: var(--txt-0);">1. In-Memory PDF Decryption</h4>
                        <p style="font-size: 0.85rem; color: var(--txt-2); margin: 0;">Password-protected CAS statements are decrypted in volatile RAM without saving unencrypted bytes to disk.</p>
                    </div>
                    <div style="padding: 1.25rem; background: var(--bg-1); border-radius: 12px;">
                        <h4 style="margin: 0 0 0.5rem 0; color: var(--txt-0);">2. Local SQLite Ledger</h4>
                        <p style="font-size: 0.85rem; color: var(--txt-2); margin: 0;">Maintains transactional history of equity, mutual fund, and ETF folios with zero third-party dependencies.</p>
                    </div>
                    <div style="padding: 1.25rem; background: var(--bg-1); border-radius: 12px;">
                        <h4 style="margin: 0 0 0.5rem 0; color: var(--txt-0);">3. Asset Rebalancing</h4>
                        <p style="font-size: 0.85rem; color: var(--txt-2); margin: 0;">Calculates exact buy/sell deltas to keep investment portfolios aligned with target equity/debt allocations.</p>
                    </div>
                </div>
            </div>
        `;
    },

    // ==========================================
    // 7. IRONPULSE GYM SHOWCASE
    // ==========================================
    renderIronPulse(state) {
        return `
            <div class="view-header">
                <div class="view-title-group">
                    <h1>IronPulse Gym Showcase & Calculator</h1>
                    <p>Client landing page with interactive multi-duration membership pricing engine.</p>
                </div>
                <div class="view-actions">
                    <a href="ironpulse-gym.html" target="_blank" class="p-btn p-btn-secondary p-btn-sm">Open Dedicated Page ↗</a>
                </div>
            </div>

            <div class="p-card">
                <div class="p-card-header">
                    <h3>Select Membership Duration (With Automatic Term Discounts)</h3>
                </div>
                <div class="p-tabs" style="border: none;">
                    <button class="p-tab-btn active" id="ip-dur-1" onclick="PortalApp.updateIronPulsePricing('1m')">Monthly</button>
                    <button class="p-tab-btn" id="ip-dur-3" onclick="PortalApp.updateIronPulsePricing('3m')">3 Months (10% Off)</button>
                    <button class="p-tab-btn" id="ip-dur-6" onclick="PortalApp.updateIronPulsePricing('6m')">6 Months (20% Off)</button>
                    <button class="p-tab-btn" id="ip-dur-12" onclick="PortalApp.updateIronPulsePricing('12m')">1 Year (30% Off)</button>
                </div>

                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; margin-top: 1.5rem;">
                    <div class="p-metric-card" style="border-top: 3px solid var(--border);">
                        <h4 style="margin: 0 0 0.5rem 0;">Access Core</h4>
                        <div class="p-metric-val" id="ip-price-core">₹2,499<span style="font-size: 0.85rem; color: var(--txt-2);">/mo</span></div>
                        <p style="font-size: 0.85rem; color: var(--txt-2);">Floor access to strength and cardio zones.</p>
                        <button class="p-btn p-btn-secondary p-btn-sm" style="width: 100%; justify-content: center; margin-top: 1rem;" onclick="PortalApp.toast('Plan selected.')">Select Plan</button>
                    </div>

                    <div class="p-metric-card" style="border-top: 3px solid var(--acc);">
                        <span class="p-badge p-badge-teal" style="margin-bottom: 0.5rem;">Most Popular</span>
                        <h4 style="margin: 0 0 0.5rem 0;">Pulse Plus</h4>
                        <div class="p-metric-val" id="ip-price-plus">₹4,299<span style="font-size: 0.85rem; color: var(--txt-2);">/mo</span></div>
                        <p style="font-size: 0.85rem; color: var(--txt-2);">All zones + recovery saunas and HIIT studio.</p>
                        <button class="p-btn p-btn-primary p-btn-sm" style="width: 100%; justify-content: center; margin-top: 1rem;" onclick="PortalApp.toast('Plan selected.')">Enroll Now</button>
                    </div>

                    <div class="p-metric-card" style="border-top: 3px solid #7c3aed;">
                        <h4 style="margin: 0 0 0.5rem 0;">Elite Coach</h4>
                        <div class="p-metric-val" id="ip-price-elite">₹8,999<span style="font-size: 0.85rem; color: var(--txt-2);">/mo</span></div>
                        <p style="font-size: 0.85rem; color: var(--txt-2);">Full access + 12 monthly 1-on-1 PT sessions.</p>
                        <button class="p-btn p-btn-secondary p-btn-sm" style="width: 100%; justify-content: center; margin-top: 1rem;" onclick="PortalApp.toast('Plan selected.')">Select Plan</button>
                    </div>
                </div>
            </div>
        `;
    },

    // ==========================================
    // 8. SETTINGS & PROFILE
    // ==========================================
    renderSettings(state) {
        return `
            <div class="view-header">
                <div class="view-title-group">
                    <h1>Portal Settings & PWA Management</h1>
                    <p>Application preferences, role permissions, and offline caching controls.</p>
                </div>
            </div>

            <div class="p-card">
                <div class="p-card-header">
                    <h3>Appearance & Theme</h3>
                </div>
                <div style="display: flex; align-items: center; justify-content: space-between; padding: 0.75rem 0;">
                    <div>
                        <strong style="color: var(--txt-0);">Dark Mode / Light Mode</strong>
                        <div style="font-size: 0.85rem; color: var(--txt-2);">Toggle between high-contrast dark theme and warm ivory light theme.</div>
                    </div>
                    <button class="p-btn p-btn-secondary" onclick="PortalApp.toggleTheme()">Switch Theme</button>
                </div>
            </div>

            <div class="p-card">
                <div class="p-card-header">
                    <h3>Progressive Web App (PWA) Storage</h3>
                </div>
                <div style="display: flex; align-items: center; justify-content: space-between; padding: 0.75rem 0;">
                    <div>
                        <strong style="color: var(--txt-0);">Service Worker Cache</strong>
                        <div style="font-size: 0.85rem; color: var(--txt-2);">Offline shell assets, stylesheets, fonts, and cached data structures.</div>
                    </div>
                    <button class="p-btn p-btn-danger p-btn-sm" onclick="PortalApp.clearCache()">Clear PWA Cache</button>
                </div>
            </div>
        `;
    }
};

window.PortalViews = PortalViews;
