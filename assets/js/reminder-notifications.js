/**
 * Reminder Notifications
 * Polls the reminders API and shows toast alerts for due/overdue reminders.
 */
(function () {
    'use strict';

    const CHECK_INTERVAL_MS = 5 * 60 * 1000; // check every 5 minutes
    const SNOOZE_KEY = 'snoozed_reminders'; // sessionStorage key
    const TOAST_DURATION_MS = 8000;

    // Resolve the correct API path regardless of whether the page lives under /pages/ or root.
    function resolveApiBase() {
        const path = window.location.pathname;
        if (path.includes('/pages/')) {
            return '../api/';
        }
        return 'api/';
    }

    function getSnoozed() {
        try {
            return JSON.parse(sessionStorage.getItem(SNOOZE_KEY) || '{}');
        } catch (e) {
            return {};
        }
    }

    function snoozeReminder(id) {
        const snoozed = getSnoozed();
        snoozed[id] = Date.now() + 30 * 60 * 1000; // snooze 30 minutes
        try {
            sessionStorage.setItem(SNOOZE_KEY, JSON.stringify(snoozed));
        } catch (e) { /* ignore quota errors */ }
    }

    function isSnoozed(id) {
        const snoozed = getSnoozed();
        return snoozed[id] && snoozed[id] > Date.now();
    }

    function ensureToastContainer() {
        let container = document.getElementById('reminder-toast-container');
        if (!container) {
            container = document.createElement('div');
            container.id = 'reminder-toast-container';
            container.setAttribute('aria-live', 'polite');
            container.style.cssText = [
                'position:fixed',
                'bottom:1.25rem',
                'right:1.25rem',
                'z-index:99999',
                'display:flex',
                'flex-direction:column',
                'gap:0.5rem',
                'pointer-events:none',
                'max-width:22rem',
                'width:100%',
            ].join(';');
            document.body.appendChild(container);
        }
        return container;
    }

    function showReminderToast(reminder) {
        const container = ensureToastContainer();

        const toast = document.createElement('div');
        toast.style.cssText = [
            'background:#fff',
            'border:1px solid #e5e7eb',
            'border-left:4px solid #f59e0b',
            'border-radius:0.5rem',
            'box-shadow:0 4px 12px rgba(0,0,0,0.15)',
            'padding:0.75rem 1rem',
            'pointer-events:all',
            'transition:opacity 0.3s ease,transform 0.3s ease',
            'opacity:0',
            'transform:translateY(0.5rem)',
        ].join(';');

        const dateLabel = reminder.reminder_date
            ? new Date(reminder.reminder_date).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
            : '';

        toast.innerHTML = `
            <div style="display:flex;align-items:flex-start;gap:0.5rem;">
                <span style="font-size:1.25rem;line-height:1;flex-shrink:0;" aria-hidden="true">&#128276;</span>
                <div style="flex:1;min-width:0;">
                    <p style="margin:0;font-size:0.875rem;font-weight:600;color:#111827;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"
                       title="${escapeHtml(reminder.title)}">${escapeHtml(reminder.title)}</p>
                    ${reminder.description
                        ? `<p style="margin:0.25rem 0 0;font-size:0.75rem;color:#6b7280;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"
                               title="${escapeHtml(reminder.description)}">${escapeHtml(reminder.description)}</p>`
                        : ''}
                    ${dateLabel ? `<p style="margin:0.25rem 0 0;font-size:0.7rem;color:#9ca3af;">Due: ${escapeHtml(dateLabel)}</p>` : ''}
                </div>
                <div style="display:flex;flex-direction:column;gap:0.25rem;flex-shrink:0;">
                    <button data-action="dismiss" title="Dismiss"
                        style="background:none;border:none;cursor:pointer;font-size:1rem;color:#9ca3af;line-height:1;padding:0;">&#10005;</button>
                    <button data-action="snooze" title="Snooze 30 min"
                        style="background:none;border:none;cursor:pointer;font-size:0.625rem;color:#6b7280;line-height:1;padding:0;white-space:nowrap;">Snooze</button>
                </div>
            </div>`;

        function dismissToast() {
            toast.style.opacity = '0';
            toast.style.transform = 'translateY(0.5rem)';
            setTimeout(() => { if (toast.parentNode) toast.parentNode.removeChild(toast); }, 350);
        }

        toast.querySelector('[data-action="dismiss"]').addEventListener('click', dismissToast);
        toast.querySelector('[data-action="snooze"]').addEventListener('click', function () {
            snoozeReminder(reminder.reminder_id || reminder.id);
            dismissToast();
        });

        container.appendChild(toast);

        // Animate in
        requestAnimationFrame(function () {
            requestAnimationFrame(function () {
                toast.style.opacity = '1';
                toast.style.transform = 'translateY(0)';
            });
        });

        // Auto-dismiss
        setTimeout(dismissToast, TOAST_DURATION_MS);
    }

    function escapeHtml(str) {
        if (!str) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    function isTodayOrOverdue(dateStr) {
        if (!dateStr) return false;
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const d = new Date(dateStr);
        d.setHours(0, 0, 0, 0);
        return d <= today;
    }

    function checkReminders() {
        const apiBase = resolveApiBase();
        fetch(apiBase + 'reminders.php', { credentials: 'same-origin' })
            .then(function (res) {
                if (!res.ok) return null;
                return res.json();
            })
            .then(function (data) {
                if (!data || !data.success || !Array.isArray(data.reminders)) return;

                data.reminders.forEach(function (reminder) {
                    const id = reminder.reminder_id || reminder.id;
                    if (!isTodayOrOverdue(reminder.reminder_date)) return;
                    if (isSnoozed(id)) return;
                    showReminderToast(reminder);
                    // Auto-snooze so it doesn't re-fire until next manual check
                    snoozeReminder(id);
                });
            })
            .catch(function () { /* silently ignore network errors */ });
    }

    // Start polling after DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    function init() {
        // Slight delay so the page finishes loading first
        setTimeout(checkReminders, 3000);
        setInterval(checkReminders, CHECK_INTERVAL_MS);
    }
}());
