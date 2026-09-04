/**
 * Shiraj Life - Interactive Homepage & Universal Command Palette Controller
 */

(function () {
    // ==========================================
    // 1. HERO SYSTEMS TERMINAL INTERACTION
    // ==========================================
    window.switchTerminalTab = function (tabId) {
        // Tab buttons
        const tabs = document.querySelectorAll('.terminal-tab-btn');
        tabs.forEach(t => {
            if (t.getAttribute('data-tab') === tabId) {
                t.classList.add('active');
            } else {
                t.classList.remove('active');
            }
        });

        // Panels
        const panels = document.querySelectorAll('.terminal-panel');
        panels.forEach(p => {
            if (p.id === `terminal-panel-${tabId}`) {
                p.classList.add('active');
            } else {
                p.classList.remove('active');
            }
        });
    };

    // Mini Wealth Calculator in Hero Terminal
    window.calcHeroTerminalWealth = function () {
        const principal = parseFloat(document.getElementById('hero-term-invest')?.value || 25000);
        const years = parseFloat(document.getElementById('hero-term-years')?.value || 10);
        const rate = 0.12; // 12% CAGR equity benchmark

        const fv = principal * (Math.pow(1 + rate, years));
        const totalInvested = principal;
        const wealthGain = fv - totalInvested;

        const valInvest = document.getElementById('hero-term-invest-val');
        if (valInvest) valInvest.textContent = `₹${principal.toLocaleString('en-IN')}`;

        const valYears = document.getElementById('hero-term-years-val');
        if (valYears) valYears.textContent = `${years} Years`;

        const outFv = document.getElementById('hero-term-fv');
        if (outFv) outFv.textContent = `₹${Math.round(fv).toLocaleString('en-IN')}`;

        const outGain = document.getElementById('hero-term-gain');
        if (outGain) outGain.textContent = `+₹${Math.round(wealthGain).toLocaleString('en-IN')} Gain (12% CAGR)`;
    };

    // Mini Gym Check-in Simulator in Hero Terminal
    window.simulateHeroTerminalCheckin = function () {
        const slots = document.querySelectorAll('.hero-gym-slot');
        const emptySlots = Array.from(slots).filter(s => !s.classList.contains('active') && !s.classList.contains('occupied'));

        if (emptySlots.length > 0) {
            const randomSlot = emptySlots[Math.floor(Math.random() * emptySlots.length)];
            randomSlot.classList.add('active', 'occupied');

            const countEl = document.getElementById('hero-gym-count');
            if (countEl) {
                const cur = parseInt(countEl.getAttribute('data-count') || 11);
                const next = cur + 1;
                countEl.setAttribute('data-count', next);
                countEl.textContent = `${next} / 16 Stations`;
            }

            if (window.showToast) {
                window.showToast(`Turnstile Verified: Station ${randomSlot.textContent.trim()} Occupied`, 'success');
            }
        } else {
            if (window.showToast) {
                window.showToast('All 16 training stations at peak capacity!', 'info');
            }
        }
    };

    // Copy Code Snippet in Hero Terminal
    window.copyHeroTerminalCode = function () {
        const code = `// Local-First Financial Audit Engine\nconst portfolio = await CASParser.decrypt(encryptedBuffer, panKey);\nconst rebalanced = AssetEngine.optimizeTax(portfolio, { stcgMax: 0.15 });`;
        navigator.clipboard.writeText(code).then(() => {
            if (window.showToast) {
                window.showToast('Architecture snippet copied to clipboard!', 'success');
            }
        });
    };

    // ==========================================
    // 2. INTERACTIVE 3-STEP PROJECT ESTIMATOR
    // ==========================================
    const estimatorState = {
        scope: 'saas', // saas, mobile, spreadsheet, crm
        scopePrice: 75000,
        scopeLabel: 'Custom SaaS Web App',
        timeline: 'sprint', // sprint, full, enterprise
        timelineMultiplier: 1.0,
        timelineLabel: 'Rapid Sprint (2-3 Weeks)'
    };

    window.selectEstimatorScope = function (scopeKey, price, label, el) {
        estimatorState.scope = scopeKey;
        estimatorState.scopePrice = price;
        estimatorState.scopeLabel = label;

        document.querySelectorAll('.scope-chip[data-scope]').forEach(c => c.classList.remove('selected'));
        if (el) el.classList.add('selected');

        updateEstimatorTotal();
    };

    window.selectEstimatorTimeline = function (timelineKey, multiplier, label, el) {
        estimatorState.timeline = timelineKey;
        estimatorState.timelineMultiplier = multiplier;
        estimatorState.timelineLabel = label;

        document.querySelectorAll('.scope-chip[data-timeline]').forEach(c => c.classList.remove('selected'));
        if (el) el.classList.add('selected');

        updateEstimatorTotal();
    };

    function updateEstimatorTotal() {
        const total = Math.round(estimatorState.scopePrice * estimatorState.timelineMultiplier);
        const formatted = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(total);

        const estVal = document.getElementById('est-summary-val');
        if (estVal) estVal.textContent = formatted;

        const estScope = document.getElementById('est-summary-scope');
        if (estScope) estScope.textContent = `${estimatorState.scopeLabel} • ${estimatorState.timelineLabel}`;

        const subjectInput = document.getElementById('subject');
        if (subjectInput) {
            subjectInput.value = `Project Inquiry: ${estimatorState.scopeLabel} (${estimatorState.timelineLabel}) ~ ${formatted}`;
        }
    }

    // ==========================================
    // 3. UNIVERSAL COMMAND PALETTE (CMD + K)
    // ==========================================
    const COMMAND_ITEMS = [
        { title: "Launchpad Operations Hub", category: "App Portal", url: "portal.html#/overview", icon: "⚡" },
        { title: "Admin Agency Console", category: "B2B Agency", url: "portal.html#/admin", icon: "💼" },
        { title: "Client Project Workspace", category: "Client Hub", url: "portal.html#/client", icon: "👤" },
        { title: "goJim Gym Management SaaS", category: "SaaS Suite", url: "portal.html#/gym", icon: "🏋️" },
        { title: "Interactive BI & Spreadsheet Suite", category: "Calculators", url: "portal.html#/tools/spreadsheets", icon: "📊" },
        { title: "Real Estate Cashflow Underwriter", category: "BI Engine", url: "spreadsheet-services.html", icon: "🏢" },
        { title: "AI Finance Manager & Wealth Parser", category: "FinTech", url: "finance-manager.html", icon: "📑" },
        { title: "IronPulse Gym Case Study & Pricing", category: "Showcase", url: "ironpulse-gym.html", icon: "🔥" },
        { title: "Opulence Luxury Salon", category: "Showcase", url: "opulence-salon.html", icon: "✨" },
        { title: "Ritu Designer Wear Portfolio", category: "Showcase", url: "ritu-designer.html", icon: "👗" },
        { title: "Services & Capabilities", category: "Website", url: "services.html", icon: "🛠️" },
        { title: "Portfolio Vault & Case Studies", category: "Website", url: "work.html", icon: "📂" },
        { title: "About & Operating Manifesto", category: "Website", url: "about.html", icon: "📖" },
        { title: "Developer Toolkit & Radar", category: "Website", url: "toolkit.html", icon: "⚙️" },
        { title: "Initiate Dialogue / Contact", category: "Connect", url: "#contact", icon: "✉️" }
    ];

    window.openCommandPalette = function () {
        let modal = document.getElementById('cmd-palette-backdrop');
        if (!modal) {
            modal = document.createElement('div');
            modal.id = 'cmd-palette-backdrop';
            modal.className = 'cmd-palette-backdrop';
            modal.innerHTML = `
                <div class="cmd-palette-dialog" role="dialog" aria-modal="true">
                    <div class="cmd-input-wrap">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--txt-2)" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                        <input type="text" id="cmd-search-input" class="cmd-search-input" placeholder="Type a command, tool, or case study..." autocomplete="off">
                        <span class="cmd-kbd-badge">ESC</span>
                    </div>
                    <div class="cmd-results-list" id="cmd-results-list"></div>
                </div>
            `;
            document.body.appendChild(modal);

            modal.addEventListener('click', (e) => {
                if (e.target === modal) closeCommandPalette();
            });

            document.getElementById('cmd-search-input').addEventListener('input', (e) => {
                renderCommandResults(e.target.value);
            });
        }

        modal.classList.add('open');
        const input = document.getElementById('cmd-search-input');
        if (input) {
            input.value = '';
            input.focus();
            renderCommandResults('');
        }
    };

    window.closeCommandPalette = function () {
        const modal = document.getElementById('cmd-palette-backdrop');
        if (modal) modal.classList.remove('open');
    };

    function renderCommandResults(query) {
        const list = document.getElementById('cmd-results-list');
        if (!list) return;

        const q = (query || '').toLowerCase().trim();
        const filtered = COMMAND_ITEMS.filter(item => {
            return item.title.toLowerCase().includes(q) || item.category.toLowerCase().includes(q);
        });

        if (filtered.length === 0) {
            list.innerHTML = `
                <div style="padding: 24px; text-align: center; color: var(--txt-2); font-size: 0.88rem;">
                    No matching commands or pages found.
                </div>
            `;
            return;
        }

        list.innerHTML = filtered.map(item => `
            <a href="${item.url}" class="cmd-item" onclick="closeCommandPalette()">
                <div class="cmd-item-left">
                    <span style="font-size: 1.1rem;">${item.icon}</span>
                    <span>${item.title}</span>
                </div>
                <span class="cmd-item-category">${item.category}</span>
            </a>
        `).join('');
    }

    // Keyboard shortcut listener (Cmd+K, Ctrl+K, Escape)
    document.addEventListener('keydown', (e) => {
        if ((e.metaKey || e.ctrlKey) && (e.key === 'k' || e.key === 'K')) {
            e.preventDefault();
            const modal = document.getElementById('cmd-palette-backdrop');
            if (modal && modal.classList.contains('open')) {
                closeCommandPalette();
            } else {
                openCommandPalette();
            }
        } else if (e.key === 'Escape') {
            closeCommandPalette();
        }
    });

    // Auto-init on load
    document.addEventListener('DOMContentLoaded', () => {
        if (document.getElementById('hero-term-invest')) {
            calcHeroTerminalWealth();
        }
        if (document.getElementById('est-summary-val')) {
            updateEstimatorTotal();
        }
    });
})();
