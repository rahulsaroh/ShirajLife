/**
 * Shiraj Life - Unified Web Portal SPA Controller
 */

const PortalApp = {
    // Application State
    state: {
        activeRoute: 'overview',
        userRole: 'admin', // admin, client, owner, trainer, student, guest
        clients: [],
        gym: {
            members: [],
            equipment: [],
            occupancy: 21,
            posCart: 0
        },
        deferredPrompt: null
    },

    // Chart instances
    charts: {
        re: null,
        saas: null,
        crm: null
    },

    // ==========================================
    // Initialization
    // ==========================================
    init() {
        this.registerServiceWorker();
        this.bindPwaInstall();
        this.loadInitialState();
        this.bindEvents();
        this.handleHashChange();
    },

    // ==========================================
    // Progressive Web App (PWA) Integration
    // ==========================================
    registerServiceWorker() {
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('./sw.js')
                    .then((reg) => {
                        console.log('[PWA] Service Worker registered with scope:', reg.scope);
                    })
                    .catch((err) => {
                        console.warn('[PWA] Service Worker registration failed:', err);
                    });
            });
        }
    },

    bindPwaInstall() {
        window.addEventListener('beforeinstallprompt', (e) => {
            e.preventDefault();
            this.state.deferredPrompt = e;
            const btn = document.getElementById('pwa-install-btn');
            if (btn) btn.style.display = 'inline-flex';
        });
    },

    promptInstall() {
        if (this.state.deferredPrompt) {
            this.state.deferredPrompt.prompt();
            this.state.deferredPrompt.userChoice.then((choiceResult) => {
                if (choiceResult.outcome === 'accepted') {
                    this.toast('Web App installation accepted!');
                }
                this.state.deferredPrompt = null;
                const btn = document.getElementById('pwa-install-btn');
                if (btn) btn.style.display = 'none';
            });
        } else {
            this.toast('App is already installed or your browser is running in standalone mode.');
        }
    },

    // ==========================================
    // State Store & Data Loading
    // ==========================================
    loadInitialState() {
        // Load Clients
        if (window.ShirajAuth && typeof window.ShirajAuth.getClients === 'function') {
            this.state.clients = window.ShirajAuth.getClients();
        } else {
            const cached = localStorage.getItem('shiraj_clients');
            if (cached) {
                try { this.state.clients = JSON.parse(cached); } catch (e) {}
            }
        }

        // Fallback default clients if empty
        if (!this.state.clients || this.state.clients.length === 0) {
            this.state.clients = [
                {
                    id: "ritu-designer",
                    username: "ritu",
                    name: "Ritu Designer Wear",
                    service: "High-Fashion E-Commerce & Bridal Portfolio",
                    totalValue: 85000,
                    amountPaid: 85000,
                    progress: 100,
                    status: "Completed",
                    renewalDate: "2026-12-01"
                },
                {
                    id: "opulence-salon",
                    username: "opulence",
                    name: "Opulence Luxury Salon",
                    service: "Salon CRM, Automated Booking & WhatsApp Bot",
                    totalValue: 65000,
                    amountPaid: 65000,
                    progress: 100,
                    status: "Completed",
                    renewalDate: "2026-11-15"
                },
                {
                    id: "ironpulse-gym",
                    username: "ironpulse",
                    name: "IronPulse Gym & Fitness",
                    service: "Gym Management Suite, Attendance & Trainer Roster",
                    totalValue: 95000,
                    amountPaid: 95000,
                    progress: 100,
                    status: "Completed",
                    renewalDate: "2026-10-30"
                }
            ];
        }

        // Load Gym / goJim state
        const gymMembers = localStorage.getItem('gojim_students');
        if (gymMembers) {
            try { this.state.gym.members = JSON.parse(gymMembers); } catch (e) {}
        }
        if (!this.state.gym.members || this.state.gym.members.length === 0) {
            this.state.gym.members = Array.from({ length: 142 }).map((_, i) => ({ id: `mem_${i + 1}`, name: `Member ${i + 1}` }));
        }

        // Check Auth User Role
        if (window.ShirajAuth && typeof window.ShirajAuth.getCurrentUser === 'function') {
            const u = window.ShirajAuth.getCurrentUser();
            if (u && u.role) {
                this.state.userRole = u.role;
            }
        }
    },

    refreshData() {
        this.loadInitialState();
        this.renderActiveView();
        this.toast('Workspace state synchronized.');
    },

    // ==========================================
    // Event Binding
    // ==========================================
    bindEvents() {
        window.addEventListener('hashchange', () => this.handleHashChange());

        // Role select change
        const roleSelect = document.getElementById('global-role-select');
        if (roleSelect) {
            roleSelect.value = this.state.userRole;
            roleSelect.addEventListener('change', (e) => {
                this.setRole(e.target.value);
            });
        }
    },

    setRole(role) {
        this.state.userRole = role;
        const roleLabel = document.getElementById('user-card-role-label');
        if (roleLabel) roleLabel.textContent = role;
        const select = document.getElementById('global-role-select');
        if (select) select.value = role;

        this.toast(`Switched preview role to: ${role.toUpperCase()}`);
        this.renderActiveView();
    },

    toggleMobileMenu() {
        const sidebar = document.getElementById('portal-sidebar');
        if (sidebar) sidebar.classList.toggle('open');
    },

    closeMobileMenu() {
        const sidebar = document.getElementById('portal-sidebar');
        if (sidebar) sidebar.classList.remove('open');
    },

    toggleTheme() {
        const current = document.documentElement.getAttribute('data-theme') || 'light';
        const next = current === 'dark' ? 'light' : 'dark';
        document.documentElement.setAttribute('data-theme', next);
        localStorage.setItem('theme', next);
        this.updateBiChartTheme();
        this.toast(`Switched to ${next} theme.`);
    },

    clearCache() {
        if ('caches' in window) {
            caches.keys().then((keys) => {
                return Promise.all(keys.map((k) => caches.delete(k)));
            }).then(() => {
                this.toast('PWA Cache cleared successfully.');
            });
        }
    },

    // ==========================================
    // Router & View Management
    // ==========================================
    navigate(route) {
        window.location.hash = `#/${route}`;
    },

    handleHashChange() {
        this.closeMobileMenu();
        const hash = window.location.hash.replace(/^#\/?/, '') || 'overview';
        const [routePath, queryString] = hash.split('?');
        const urlParams = new URLSearchParams(queryString || '');

        this.state.activeRoute = routePath || 'overview';
        this.state.currentQuery = urlParams;

        this.updateSidebarNav(routePath);
        this.updateBreadcrumbs(routePath);
        this.renderActiveView();
    },

    updateSidebarNav(route) {
        const navItems = document.querySelectorAll('.portal-nav-item');
        navItems.forEach((item) => {
            const routeTarget = item.getAttribute('data-route');
            if (routeTarget && (route === routeTarget || route.startsWith(routeTarget + '/'))) {
                item.classList.add('active');
            } else {
                item.classList.remove('active');
            }
        });
    },

    updateBreadcrumbs(route) {
        const crumbCurrent = document.getElementById('breadcrumb-current');
        if (!crumbCurrent) return;

        const routeNames = {
            'overview': 'Launchpad',
            'admin': 'Admin Console',
            'client': 'Client Project Hub',
            'gym': 'goJim SaaS',
            'gym/owner': 'goJim > Owner',
            'gym/trainer': 'goJim > Trainer',
            'gym/student': 'goJim > Member Pass',
            'tools/spreadsheets': 'BI & Spreadsheet Engines',
            'tools/finance': 'AI Finance Manager',
            'showcases/ironpulse': 'IronPulse Showcase',
            'settings': 'Settings & PWA'
        };

        crumbCurrent.textContent = routeNames[route] || 'Workspace';
    },

    renderActiveView() {
        const container = document.getElementById('portal-view-container');
        if (!container || !window.PortalViews) return;

        const route = this.state.activeRoute;
        const params = this.state.currentQuery || new URLSearchParams();

        if (route === 'overview' || route === '') {
            container.innerHTML = PortalViews.renderOverview(this.state);
        } else if (route === 'admin') {
            container.innerHTML = PortalViews.renderAdmin(this.state);
        } else if (route === 'client') {
            const previewId = params.get('preview') || (this.state.clients[0] ? this.state.clients[0].id : 'ritu-designer');
            container.innerHTML = PortalViews.renderClient(this.state, previewId);
        } else if (route.startsWith('gym')) {
            const subRole = route === 'gym/trainer' ? 'trainer' : (route === 'gym/student' ? 'student' : 'owner');
            container.innerHTML = PortalViews.renderGym(this.state, subRole);
        } else if (route === 'tools/spreadsheets') {
            container.innerHTML = PortalViews.renderSpreadsheets(this.state);
            setTimeout(() => {
                this.initBiCharts();
                this.runRealEstateCalc();
            }, 50);
        } else if (route === 'tools/finance') {
            container.innerHTML = PortalViews.renderFinance(this.state);
        } else if (route === 'showcases/ironpulse') {
            container.innerHTML = PortalViews.renderIronPulse(this.state);
        } else if (route === 'settings') {
            container.innerHTML = PortalViews.renderSettings(this.state);
        } else {
            container.innerHTML = PortalViews.renderOverview(this.state);
        }

        window.scrollTo({ top: 0, behavior: 'instant' });
    },

    // ==========================================
    // Interactive Features & Calculations
    // ==========================================

    // --- BI Tab Switching & Calculators ---
    switchBiTab(tabId) {
        document.getElementById('bi-tab-re-panel').style.display = tabId === 're' ? 'block' : 'none';
        document.getElementById('bi-tab-saas-panel').style.display = tabId === 'saas' ? 'block' : 'none';
        document.getElementById('bi-tab-sales-panel').style.display = tabId === 'sales' ? 'block' : 'none';

        ['re', 'saas', 'sales'].forEach(t => {
            const btn = document.getElementById(`btn-tab-${t}`);
            if (btn) {
                if (t === tabId) btn.classList.add('active');
                else btn.classList.remove('active');
            }
        });

        if (tabId === 're') this.runRealEstateCalc();
        if (tabId === 'saas') this.runSaasCalc();
        if (tabId === 'sales') this.runCrmCalc();
    },

    runRealEstateCalc() {
        const price = parseFloat(document.getElementById('re-in-price')?.value || 350000);
        const downPct = parseFloat(document.getElementById('re-in-down')?.value || 20);
        const rate = parseFloat(document.getElementById('re-in-rate')?.value || 6.5);
        const rent = parseFloat(document.getElementById('re-in-rent')?.value || 3200);

        const downVal = price * (downPct / 100);
        const loan = price - downVal;
        const monthlyRate = (rate / 100) / 12;
        const nMonths = 360;
        const mortgage = loan * (monthlyRate * Math.pow(1 + monthlyRate, nMonths)) / (Math.pow(1 + monthlyRate, nMonths) - 1);
        const opex = rent * 0.35; // 35% OpEx (Taxes, Insurance, Maintenance)
        const netCashflow = rent - mortgage - opex;
        const capRate = ((rent * 12 * 0.65) / price) * 100;

        document.getElementById('re-val-price').textContent = `$${price.toLocaleString()}`;
        document.getElementById('re-val-down').textContent = `${downPct}% ($${downVal.toLocaleString()})`;
        document.getElementById('re-val-rate').textContent = `${rate.toFixed(1)}%`;
        document.getElementById('re-val-rent').textContent = `$${rent.toLocaleString()}`;

        const flowEl = document.getElementById('re-out-cashflow');
        if (flowEl) {
            flowEl.textContent = `${netCashflow >= 0 ? '+' : ''}$${Math.round(netCashflow).toLocaleString()}`;
            flowEl.style.color = netCashflow >= 0 ? '#10b981' : '#ef4444';
        }
        const capEl = document.getElementById('re-out-cap');
        if (capEl) capEl.textContent = `${capRate.toFixed(1)}%`;

        const verdictEl = document.getElementById('re-verdict');
        if (verdictEl) {
            if (netCashflow > 400 && capRate >= 7.0) {
                verdictEl.className = 'p-verdict p-verdict-strong';
                verdictEl.textContent = 'STRONG DEAL';
            } else if (netCashflow >= 0) {
                verdictEl.className = 'p-verdict p-verdict-moderate';
                verdictEl.textContent = 'MODERATE';
            } else {
                verdictEl.className = 'p-verdict p-verdict-risk';
                verdictEl.textContent = 'HIGH RISK';
            }
        }

        this.updateReChart(rent, mortgage, opex, netCashflow);
    },

    runSaasCalc() {
        const reserves = parseFloat(document.getElementById('saas-in-reserves')?.value || 120000);
        const mrr = parseFloat(document.getElementById('saas-in-mrr')?.value || 18000);
        const burn = parseFloat(document.getElementById('saas-in-burn')?.value || 14500);

        document.getElementById('saas-val-reserves').textContent = `$${reserves.toLocaleString()}`;
        document.getElementById('saas-val-mrr').textContent = `$${mrr.toLocaleString()}`;
        document.getElementById('saas-val-burn').textContent = `$${burn.toLocaleString()}`;

        const netMargin = mrr - burn;
        const arr = mrr * 12;

        const marginEl = document.getElementById('saas-out-margin');
        if (marginEl) {
            marginEl.textContent = `${netMargin >= 0 ? '+' : ''}$${netMargin.toLocaleString()}`;
            marginEl.style.color = netMargin >= 0 ? '#10b981' : '#ef4444';
        }
        const arrEl = document.getElementById('saas-out-arr');
        if (arrEl) arrEl.textContent = `$${arr.toLocaleString()}`;

        const verdictEl = document.getElementById('saas-verdict');
        if (verdictEl) {
            if (netMargin >= 0) {
                verdictEl.className = 'p-verdict p-verdict-strong';
                verdictEl.textContent = 'PROFITABLE';
            } else {
                const runwayMonths = Math.floor(reserves / Math.abs(netMargin));
                if (runwayMonths > 12) {
                    verdictEl.className = 'p-verdict p-verdict-moderate';
                    verdictEl.textContent = `${runwayMonths}M RUNWAY`;
                } else {
                    verdictEl.className = 'p-verdict p-verdict-risk';
                    verdictEl.textContent = `${runwayMonths}M BURN CRITICAL`;
                }
            }
        }

        this.updateSaasChart(mrr, burn);
    },

    runCrmCalc() {
        const leads = parseFloat(document.getElementById('crm-in-leads')?.value || 50);
        const size = parseFloat(document.getElementById('crm-in-size')?.value || 4500);
        const rate = parseFloat(document.getElementById('crm-in-rate')?.value || 22);

        document.getElementById('crm-val-leads').textContent = leads;
        document.getElementById('crm-val-size').textContent = `$${size.toLocaleString()}`;
        document.getElementById('crm-val-rate').textContent = `${rate}%`;

        const wonDeals = Math.round(leads * (rate / 100));
        const projectedRev = wonDeals * size;

        const revEl = document.getElementById('crm-out-rev');
        if (revEl) revEl.textContent = `$${projectedRev.toLocaleString()}`;
        const wonEl = document.getElementById('crm-out-won');
        if (wonEl) wonEl.textContent = `${wonDeals} Deals`;

        this.updateCrmChart(leads, Math.round(leads * 0.6), wonDeals);
    },

    // --- Chart.js Initializers ---
    initBiCharts() {
        if (!window.Chart) return;
        const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
        const txtColor = isDark ? '#98a1ad' : '#434850';
        const gridColor = isDark ? 'rgba(236,240,246,0.06)' : 'rgba(13,15,17,0.06)';

        // Chart 1: Real Estate
        const reCtx = document.getElementById('re-chart-canvas')?.getContext('2d');
        if (reCtx) {
            if (this.charts.re) this.charts.re.destroy();
            this.charts.re = new Chart(reCtx, {
                type: 'bar',
                data: {
                    labels: ['Gross Rent', 'Mortgage P&I', 'OpEx (35%)', 'Net Cashflow'],
                    datasets: [{
                        data: [3200, 1770, 1120, 310],
                        backgroundColor: ['#0e6b62', '#ef4444', '#f59e0b', '#10b981'],
                        borderRadius: 8
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        y: { grid: { color: gridColor }, ticks: { color: txtColor } },
                        x: { grid: { display: false }, ticks: { color: txtColor } }
                    }
                }
            });
        }

        // Chart 2: SaaS Runway
        const saasCtx = document.getElementById('saas-chart-canvas')?.getContext('2d');
        if (saasCtx) {
            if (this.charts.saas) this.charts.saas.destroy();
            this.charts.saas = new Chart(saasCtx, {
                type: 'line',
                data: {
                    labels: ['Month 1', 'Month 2', 'Month 3', 'Month 4', 'Month 5', 'Month 6'],
                    datasets: [
                        { label: 'MRR', data: [18000, 19800, 21780, 23950, 26350, 29000], borderColor: '#10b981', tension: 0.3 },
                        { label: 'Burn', data: [14500, 14800, 15200, 15500, 16000, 16500], borderColor: '#ef4444', tension: 0.3 }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { labels: { color: txtColor } } },
                    scales: {
                        y: { grid: { color: gridColor }, ticks: { color: txtColor } },
                        x: { grid: { display: false }, ticks: { color: txtColor } }
                    }
                }
            });
        }

        // Chart 3: CRM Funnel
        const crmCtx = document.getElementById('crm-chart-canvas')?.getContext('2d');
        if (crmCtx) {
            if (this.charts.crm) this.charts.crm.destroy();
            this.charts.crm = new Chart(crmCtx, {
                type: 'bar',
                data: {
                    labels: ['Inbound Leads', 'Qualified Pitches', 'Closed Won'],
                    datasets: [{
                        data: [50, 30, 11],
                        backgroundColor: ['#38bdf8', '#818cf8', '#10b981'],
                        borderRadius: 8
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        y: { grid: { color: gridColor }, ticks: { color: txtColor } },
                        x: { grid: { display: false }, ticks: { color: txtColor } }
                    }
                }
            });
        }
    },

    updateReChart(rent, mortgage, opex, cashflow) {
        if (this.charts.re) {
            this.charts.re.data.datasets[0].data = [rent, Math.round(mortgage), Math.round(opex), Math.round(cashflow)];
            this.charts.re.update();
        }
    },

    updateSaasChart(mrr, burn) {
        if (this.charts.saas) {
            this.charts.saas.data.datasets[0].data = [mrr, mrr * 1.08, mrr * 1.16, mrr * 1.25, mrr * 1.34, mrr * 1.45];
            this.charts.saas.data.datasets[1].data = [burn, burn * 1.02, burn * 1.04, burn * 1.06, burn * 1.08, burn * 1.10];
            this.charts.saas.update();
        }
    },

    updateCrmChart(leads, pitches, won) {
        if (this.charts.crm) {
            this.charts.crm.data.datasets[0].data = [leads, pitches, won];
            this.charts.crm.update();
        }
    },

    updateBiChartTheme() {
        if (this.state.activeRoute === 'tools/spreadsheets') {
            this.initBiCharts();
            this.runRealEstateCalc();
        }
    },

    // --- IronPulse Pricing Selector ---
    updateIronPulsePricing(dur) {
        const prices = {
            '1m': { core: '₹2,499', plus: '₹4,299', elite: '₹8,999' },
            '3m': { core: '₹2,249', plus: '₹3,869', elite: '₹8,099' },
            '6m': { core: '₹1,999', plus: '₹3,439', elite: '₹7,199' },
            '12m': { core: '₹1,749', plus: '₹3,009', elite: '₹6,299' }
        };

        ['1m', '3m', '6m', '12m'].forEach(d => {
            const btn = document.getElementById(`ip-dur-${d.replace('m', '')}`);
            if (btn) {
                if (d === dur) btn.classList.add('active');
                else btn.classList.remove('active');
            }
        });

        const p = prices[dur] || prices['1m'];
        if (document.getElementById('ip-price-core')) document.getElementById('ip-price-core').innerHTML = `${p.core}<span style="font-size: 0.85rem; color: var(--txt-2);">/mo</span>`;
        if (document.getElementById('ip-price-plus')) document.getElementById('ip-price-plus').innerHTML = `${p.plus}<span style="font-size: 0.85rem; color: var(--txt-2);">/mo</span>`;
        if (document.getElementById('ip-price-elite')) document.getElementById('ip-price-elite').innerHTML = `${p.elite}<span style="font-size: 0.85rem; color: var(--txt-2);">/mo</span>`;
    },

    // --- Gym Operations ---
    simulateCheckIn() {
        const cells = document.querySelectorAll('.p-heatmap-cell');
        const emptyCells = Array.from(cells).filter(c => !c.classList.contains('occupied'));
        if (emptyCells.length > 0) {
            const randomCell = emptyCells[Math.floor(Math.random() * emptyCells.length)];
            randomCell.classList.add('occupied');
            this.state.gym.occupancy = (this.state.gym.occupancy || 21) + 1;
            const countEl = document.getElementById('gym-occupancy-count');
            if (countEl) countEl.textContent = `${this.state.gym.occupancy} / 32`;
            this.toast(`Member badge verified. Station ${randomCell.textContent} occupied.`);
        } else {
            this.toast('Gym floor is at 100% capacity.');
        }
    },

    addToPosCart(price, name) {
        this.state.gym.posCart = (this.state.gym.posCart || 0) + price;
        const badge = document.getElementById('pos-cart-badge');
        if (badge) badge.textContent = `Cart: ₹${this.state.gym.posCart.toLocaleString()}`;
        this.toast(`Added ${name} (+₹${price}) to checkout.`);
    },

    posCheckout() {
        if (!this.state.gym.posCart || this.state.gym.posCart === 0) {
            this.toast('POS cart is empty. Add items first.');
            return;
        }
        const total = this.state.gym.posCart;
        this.state.gym.posCart = 0;
        const badge = document.getElementById('pos-cart-badge');
        if (badge) badge.textContent = 'Cart: ₹0';
        this.toast(`Charged ₹${total.toLocaleString()} to member account #IP-9842.`);
    },

    // --- Admin Filters & Modals ---
    filterAdminClients(query) {
        const q = (query || '').toLowerCase();
        const rows = document.querySelectorAll('#admin-clients-table tbody tr');
        rows.forEach(r => {
            const text = r.textContent.toLowerCase();
            r.style.display = text.includes(q) ? '' : 'none';
        });
    },

    sendClientMessage() {
        const input = document.getElementById('client-msg-input');
        if (input && input.value.trim()) {
            const msg = input.value.trim();
            input.value = '';
            this.toast(`Message dispatched: "${msg}"`);
        }
    },

    showQuickReply(clientName) {
        this.openModal(`
            <div class="p-form-group">
                <label class="p-form-label">Recipient</label>
                <input type="text" class="p-input" value="${clientName}" readonly>
            </div>
            <div class="p-form-group">
                <label class="p-form-label">Quick Reply Message</label>
                <textarea class="p-textarea" rows="4" id="quick-reply-text" placeholder="Type message..."></textarea>
            </div>
        `, `Reply to ${clientName}`, () => {
            const text = document.getElementById('quick-reply-text')?.value;
            if (text) this.toast(`Reply sent to ${clientName}`);
            this.closeModal();
        });
    },

    openAddClientModal() {
        this.openModal(`
            <div class="p-form-group">
                <label class="p-form-label">Client / Business Name</label>
                <input type="text" id="modal-client-name" class="p-input" placeholder="e.g. Apex Health Clinic">
            </div>
            <div class="p-form-group">
                <label class="p-form-label">Service Scope</label>
                <input type="text" id="modal-client-service" class="p-input" placeholder="e.g. Next.js SaaS Webapp">
            </div>
            <div class="p-form-group">
                <label class="p-form-label">Contract Value (INR)</label>
                <input type="number" id="modal-client-val" class="p-input" placeholder="75000">
            </div>
        `, 'Add New B2B Client', () => {
            const name = document.getElementById('modal-client-name')?.value;
            const service = document.getElementById('modal-client-service')?.value;
            const val = parseFloat(document.getElementById('modal-client-val')?.value || 0);

            if (name && service) {
                const newClient = {
                    id: name.toLowerCase().replace(/\s+/g, '-'),
                    username: name.toLowerCase().replace(/\s+/g, ''),
                    name: name,
                    service: service,
                    totalValue: val,
                    amountPaid: 0,
                    progress: 10,
                    status: 'Active'
                };
                this.state.clients.push(newClient);
                localStorage.setItem('shiraj_clients', JSON.stringify(this.state.clients));
                this.renderActiveView();
                this.toast(`Client "${name}" provisioned successfully.`);
                this.closeModal();
            }
        });
    },

    openEditClientModal(id) {
        const client = this.state.clients.find(c => c.id === id);
        if (!client) return;

        this.openModal(`
            <div class="p-form-group">
                <label class="p-form-label">Client Name</label>
                <input type="text" id="modal-edit-name" class="p-input" value="${client.name}">
            </div>
            <div class="p-form-group">
                <label class="p-form-label">Progress (%): <span id="modal-prog-val">${client.progress || 0}%</span></label>
                <input type="range" class="p-range-input" min="0" max="100" value="${client.progress || 0}" oninput="document.getElementById('modal-prog-val').textContent = this.value + '%'" id="modal-edit-prog">
            </div>
            <div class="p-form-group">
                <label class="p-form-label">Amount Paid (INR)</label>
                <input type="number" id="modal-edit-paid" class="p-input" value="${client.amountPaid || 0}">
            </div>
        `, `Edit: ${client.name}`, () => {
            client.name = document.getElementById('modal-edit-name')?.value || client.name;
            client.progress = parseInt(document.getElementById('modal-edit-prog')?.value || client.progress);
            client.amountPaid = parseFloat(document.getElementById('modal-edit-paid')?.value || client.amountPaid);
            if (client.progress === 100) client.status = 'Completed';
            localStorage.setItem('shiraj_clients', JSON.stringify(this.state.clients));
            this.renderActiveView();
            this.toast(`Client "${client.name}" updated.`);
            this.closeModal();
        });
    },

    openTicketModal() {
        this.openModal(`
            <div class="p-form-group">
                <label class="p-form-label">Machine / Equipment ID</label>
                <input type="text" class="p-input" placeholder="#EQ-08 Cable Column">
            </div>
            <div class="p-form-group">
                <label class="p-form-label">Issue Description</label>
                <textarea class="p-textarea" rows="3" placeholder="Describe mechanical fault or maintenance requirement..."></textarea>
            </div>
        `, 'Report Equipment Issue', () => {
            this.toast('Equipment service ticket logged.');
            this.closeModal();
        });
    },

    // --- Modal System ---
    openModal(bodyHtml, title = 'Modal', onConfirm = null) {
        let backdrop = document.getElementById('portal-modal-backdrop');
        if (!backdrop) {
            backdrop = document.createElement('div');
            backdrop.id = 'portal-modal-backdrop';
            backdrop.className = 'portal-modal-backdrop';
            backdrop.innerHTML = `
                <div class="portal-modal">
                    <div class="portal-modal-header">
                        <h3 id="portal-modal-title"></h3>
                        <button class="portal-btn-icon" onclick="PortalApp.closeModal()">✕</button>
                    </div>
                    <div class="portal-modal-body" id="portal-modal-body"></div>
                    <div class="portal-modal-footer">
                        <button class="p-btn p-btn-secondary" onclick="PortalApp.closeModal()">Cancel</button>
                        <button class="p-btn p-btn-primary" id="portal-modal-confirm-btn">Confirm</button>
                    </div>
                </div>
            `;
            document.body.appendChild(backdrop);
        }

        document.getElementById('portal-modal-title').textContent = title;
        document.getElementById('portal-modal-body').innerHTML = bodyHtml;

        const confirmBtn = document.getElementById('portal-modal-confirm-btn');
        confirmBtn.onclick = onConfirm || (() => this.closeModal());

        backdrop.classList.add('open');
    },

    closeModal() {
        const backdrop = document.getElementById('portal-modal-backdrop');
        if (backdrop) backdrop.classList.remove('open');
    },

    // --- Toast System ---
    toast(msg) {
        let container = document.getElementById('portal-toast-container');
        if (!container) {
            container = document.createElement('div');
            container.id = 'portal-toast-container';
            document.body.appendChild(container);
        }

        const t = document.createElement('div');
        t.className = 'portal-toast';
        t.innerHTML = `
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--acc)" stroke-width="2.5"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
            <span>${msg}</span>
        `;
        container.appendChild(t);

        setTimeout(() => {
            t.style.opacity = '0';
            t.style.transform = 'translateY(10px)';
            t.style.transition = 'all 0.3s ease';
            setTimeout(() => t.remove(), 300);
        }, 3200);
    }
};

window.PortalApp = PortalApp;

// Auto-boot on DOMContentLoaded
document.addEventListener('DOMContentLoaded', () => {
    PortalApp.init();
});
