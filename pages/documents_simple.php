<?php
require_once __DIR__ . '/../includes/config.php';

if (!isset($_SESSION['user_id'])) {
    echo "<div class='bg-white rounded-xl shadow p-6'><p class='text-red-600'>You must be logged in to view documents.</p></div>";
    return;
}

// Fetch latest documents (lightweight query, safe for production)
$sql = "SELECT d.document_id, d.title, d.status, d.created_at, d.updated_at, dt.type_name
        FROM documents d
        LEFT JOIN document_types dt ON d.type_id = dt.type_id
        ORDER BY d.updated_at DESC
        LIMIT 100";

$result = $conn->query($sql);

$documents = [];
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $documents[] = $row;
    }
}

// Helper for status badge
function get_status_classes($status) {
    $status = strtolower($status ?? 'draft');
    switch ($status) {
        case 'approved':
            return 'bg-green-100 text-green-800';
        case 'pending':
            return 'bg-yellow-100 text-yellow-800';
        case 'rejected':
            return 'bg-red-100 text-red-800';
        case 'revision':
        case 'revision_requested':
            return 'bg-purple-100 text-purple-800';
        default:
            return 'bg-gray-100 text-gray-800';
    }
}
?>

<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 space-y-4">
  <!-- Header / summary -->
  <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-gray-900 tracking-tight">Documents</h1>
      <p class="text-sm text-gray-500 mt-1">
        Showing latest <?php echo count($documents); ?> documents. Use filters or AI tools to explore and understand documents faster.
      </p>
    </div>
    <div class="flex flex-wrap items-center gap-2 text-xs">
      <span class="inline-flex items-center gap-1 rounded-full bg-sky-50 text-sky-700 px-3 py-1 border border-sky-100">
        <span class="w-1.5 h-1.5 rounded-full bg-sky-500"></span>
        AI tools: Summarize &amp; Analyze
      </span>
      <span class="inline-flex items-center gap-1 rounded-full bg-gray-50 text-gray-600 px-3 py-1 border border-gray-100">
        <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
        Stable on server (no heavy parsing on load)
      </span>
    </div>
  </div>

  <!-- Filters / search -->
  <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
    <div class="flex flex-wrap gap-2">
      <?php
        $statusFilters = [
            'all' => 'All',
            'pending' => 'Pending',
            'approved' => 'Approved',
            'revision' => 'Revision',
            'rejected' => 'Rejected',
            'draft' => 'Draft'
        ];
      ?>
      <?php foreach ($statusFilters as $key => $label): ?>
        <button
          type="button"
          class="status-filter inline-flex items-center px-3 py-1.5 rounded-full border text-xs font-medium transition-colors
                 <?php echo $key === 'all' ? 'bg-emerald-50 text-emerald-700 border-emerald-100' : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'; ?>"
          data-status-filter="<?php echo htmlspecialchars($key, ENT_QUOTES, 'UTF-8'); ?>"
        >
          <?php echo htmlspecialchars($label, ENT_QUOTES, 'UTF-8'); ?>
        </button>
      <?php endforeach; ?>
    </div>

    <div class="flex items-center gap-2 w-full md:w-80">
      <div class="relative flex-1">
        <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <svg class="h-4 w-4 text-gray-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-4.35-4.35M11 18a7 7 0 100-14 7 7 0 000 14z" />
          </svg>
        </span>
        <input
          id="documents-search-input"
          type="text"
          placeholder="Search by title or type..."
          class="w-full pl-9 pr-3 py-2 text-sm border border-gray-200 rounded-full focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
        />
      </div>
    </div>
  </div>

  <!-- Documents table -->
  <?php if (!empty($documents)): ?>
    <div class="overflow-x-auto border border-gray-100 rounded-xl">
      <table class="min-w-full text-sm">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Title</th>
            <th class="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Type</th>
            <th class="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
            <th class="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Created</th>
            <th class="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Last Updated</th>
            <th class="px-3 py-2 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">AI Actions</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-100" id="documents-table-body">
          <?php foreach ($documents as $row): ?>
            <?php
              $docId   = (int)$row['document_id'];
              $title   = $row['title'] ?: 'Untitled';
              $type    = $row['type_name'] ?: 'N/A';
              $status  = $row['status'] ?: 'draft';
              $created = $row['created_at'] ?: '';
              $updated = $row['updated_at'] ?: '';

              $statusLabel   = strtoupper($status);
              $statusClasses = get_status_classes($status);
            ?>
            <tr
              class="hover:bg-gray-50 transition-colors"
              data-doc-row="1"
              data-status="<?php echo htmlspecialchars(strtolower($status), ENT_QUOTES, 'UTF-8'); ?>"
              data-title="<?php echo htmlspecialchars(mb_strtolower($title), ENT_QUOTES, 'UTF-8'); ?>"
              data-type="<?php echo htmlspecialchars(mb_strtolower($type), ENT_QUOTES, 'UTF-8'); ?>"
            >
              <td class="px-3 py-2 whitespace-nowrap">
                <a
                  href="?page=view_document&id=<?php echo $docId; ?>"
                  class="text-sm font-medium text-gray-900 hover:text-emerald-700 hover:underline"
                >
                  <?php echo htmlspecialchars($title, ENT_QUOTES, 'UTF-8'); ?>
                </a>
              </td>
              <td class="px-3 py-2 whitespace-nowrap text-gray-700">
                <?php echo htmlspecialchars($type, ENT_QUOTES, 'UTF-8'); ?>
              </td>
              <td class="px-3 py-2 whitespace-nowrap">
                <span class="inline-flex px-2.5 py-1 text-xs font-medium rounded-full <?php echo $statusClasses; ?>">
                  <?php echo htmlspecialchars($statusLabel, ENT_QUOTES, 'UTF-8'); ?>
                </span>
              </td>
              <td class="px-3 py-2 whitespace-nowrap text-gray-600 text-xs">
                <?php echo htmlspecialchars($created, ENT_QUOTES, 'UTF-8'); ?>
              </td>
              <td class="px-3 py-2 whitespace-nowrap text-gray-600 text-xs">
                <?php echo htmlspecialchars($updated, ENT_QUOTES, 'UTF-8'); ?>
              </td>
              <td class="px-3 py-2 whitespace-nowrap text-right">
                <div class="inline-flex items-center gap-2">
                  <button
                    type="button"
                    class="ai-btn-summarize inline-flex items-center px-2.5 py-1 text-xs font-medium rounded-full border border-emerald-100 text-emerald-700 bg-emerald-50 hover:bg-emerald-100 transition-colors"
                    data-doc-id="<?php echo $docId; ?>"
                    data-doc-title="<?php echo htmlspecialchars($title, ENT_QUOTES, 'UTF-8'); ?>"
                  >
                    Summarize
                  </button>
                  <button
                    type="button"
                    class="ai-btn-analyze inline-flex items-center px-2.5 py-1 text-xs font-medium rounded-full border border-sky-100 text-sky-700 bg-sky-50 hover:bg-sky-100 transition-colors"
                    data-doc-id="<?php echo $docId; ?>"
                    data-doc-title="<?php echo htmlspecialchars($title, ENT_QUOTES, 'UTF-8'); ?>"
                  >
                    Analyze
                  </button>
                </div>
              </td>
            </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  <?php else: ?>
    <p class="text-gray-500 text-sm">No documents found.</p>
  <?php endif; ?>
</div>

<!-- AI Result Modal -->
<div
  id="documents-ai-modal"
  class="fixed inset-0 z-40 hidden items-center justify-center bg-black bg-opacity-30 backdrop-blur-sm"
>
  <div class="bg-white rounded-2xl shadow-xl max-w-3xl w-full mx-4 max-h-[80vh] flex flex-col">
    <div class="flex items-center justify-between px-5 py-3 border-b border-gray-100">
      <div>
        <p id="documents-ai-modal-title" class="text-sm font-semibold text-gray-900">AI Result</p>
        <p id="documents-ai-modal-subtitle" class="text-xs text-gray-500"></p>
      </div>
      <button
        type="button"
        id="documents-ai-modal-close"
        class="p-1 rounded-full text-gray-400 hover:text-gray-600 hover:bg-gray-100"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
        </svg>
      </button>
    </div>
    <div id="documents-ai-modal-body" class="px-5 py-4 overflow-y-auto text-sm text-gray-800 space-y-3">
      <div class="flex items-center gap-2 text-gray-500 text-sm">
        <svg class="h-4 w-4 animate-spin text-emerald-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4l3-3-3-3v4a8 8 0 100 16v-4l-3 3 3 3v-4a8 8 0 01-8-8z"></path>
        </svg>
        <span>Asking AI, please wait…</span>
      </div>
    </div>
    <div class="px-5 py-3 border-t border-gray-100 flex items-center justify-between text-xs text-gray-500">
      <span>Powered by Gemini. Responses may contain inaccuracies.</span>
      <button
        type="button"
        id="documents-ai-modal-close-bottom"
        class="px-3 py-1.5 rounded-full border border-gray-200 text-gray-600 hover:bg-gray-50"
      >
        Close
      </button>
    </div>
  </div>
</div>

<script>
(function() {
  const rows = Array.from(document.querySelectorAll('[data-doc-row="1"]'));
  const searchInput = document.getElementById('documents-search-input');
  const statusButtons = Array.from(document.querySelectorAll('.status-filter'));
  let currentStatus = 'all';

  function applyFilters() {
    const q = (searchInput?.value || '').trim().toLowerCase();

    rows.forEach(row => {
      const rowStatus = (row.dataset.status || '').toLowerCase();
      const title = row.dataset.title || '';
      const type = row.dataset.type || '';

      const matchesStatus = currentStatus === 'all' || rowStatus === currentStatus;
      const matchesSearch = !q || title.includes(q) || type.includes(q);

      row.style.display = (matchesStatus && matchesSearch) ? '' : 'none';
    });
  }

  statusButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const status = btn.dataset.statusFilter || 'all';
      currentStatus = status;

      statusButtons.forEach(b => {
        b.classList.remove('bg-emerald-50','text-emerald-700','border-emerald-100');
        b.classList.add('bg-white','text-gray-600','border-gray-200');
      });

      btn.classList.remove('bg-white','text-gray-600','border-gray-200');
      btn.classList.add('bg-emerald-50','text-emerald-700','border-emerald-100');

      applyFilters();
    });
  });

  if (searchInput) {
    searchInput.addEventListener('input', () => {
      applyFilters();
    });
  }

  // AI modal helpers
  const modal = document.getElementById('documents-ai-modal');
  const modalTitle = document.getElementById('documents-ai-modal-title');
  const modalSubtitle = document.getElementById('documents-ai-modal-subtitle');
  const modalBody = document.getElementById('documents-ai-modal-body');
  const closeButtons = [
    document.getElementById('documents-ai-modal-close'),
    document.getElementById('documents-ai-modal-close-bottom'),
  ].filter(Boolean);

  function openModal(title, subtitle, initialHtml) {
    if (!modal) return;
    modalTitle.textContent = title || 'AI Result';
    modalSubtitle.textContent = subtitle || '';
    modalBody.innerHTML = initialHtml || '<p class="text-sm text-gray-500">Loading…</p>';
    modal.classList.remove('hidden');
    modal.classList.add('flex');
  }

  function closeModal() {
    if (!modal) return;
    modal.classList.add('hidden');
    modal.classList.remove('flex');
  }

  closeButtons.forEach(btn => btn.addEventListener('click', closeModal));
  if (modal) {
    modal.addEventListener('click', (e) => {
      if (e.target === modal) closeModal();
    });
  }

  function renderSummaryResult(data) {
    if (!data || data.success === false) {
      const msg = data && data.message ? data.message : 'AI summarization failed. Please try again later.';
      modalBody.innerHTML = '<p class="text-sm text-red-600">' + msg + '</p>';
      return;
    }

    const summary = data.summary || '';
    const keyPoints = Array.isArray(data.keyPoints) ? data.keyPoints : [];

    let html = '';
    if (summary) {
      html += '<h3 class="text-sm font-semibold text-gray-900 mb-1">Summary</h3>';
      html += '<p class="text-sm text-gray-800 mb-3 whitespace-pre-line">' + summary + '</p>';
    }
    if (keyPoints.length) {
      html += '<h3 class="text-sm font-semibold text-gray-900 mb-1">Key Points</h3>';
      html += '<ul class="list-disc pl-5 space-y-1 text-sm text-gray-800">';
      keyPoints.forEach(pt => {
        html += '<li>' + String(pt) + '</li>';
      });
      html += '</ul>';
    }
    if (!html) {
      html = '<p class="text-sm text-gray-500">No structured summary returned.</p>';
    }
    modalBody.innerHTML = html;
  }

  function renderAnalysisResult(data) {
    if (!data || data.success === false) {
      const msg = data && data.message ? data.message : 'AI analysis failed. Please try again later.';
      modalBody.innerHTML = '<p class="text-sm text-red-600">' + msg + '</p>';
      return;
    }

    let html = '<div class="space-y-4">';

    if (Array.isArray(data.classification) && data.classification.length) {
      html += '<div><h3 class="text-sm font-semibold text-gray-900 mb-1">Classification</h3>';
      html += '<ul class="space-y-1 text-sm text-gray-800">';
      data.classification.forEach(c => {
        const name = c.name || c.label || 'Category';
        const conf = typeof c.confidence !== 'undefined' ? ' (' + c.confidence + '%)' : '';
        html += '<li>• ' + name + conf + '</li>';
      });
      html += '</ul></div>';
    }

    if (Array.isArray(data.entities) && data.entities.length) {
      html += '<div><h3 class="text-sm font-semibold text-gray-900 mb-1">Entities</h3>';
      html += '<div class="flex flex-wrap gap-1.5">';
      data.entities.forEach(e => {
        const text = e.text || '';
        const type = e.type || '';
        if (!text) return;
        html += '<span class="inline-flex items-center px-2 py-0.5 rounded-full bg-gray-100 text-gray-800 text-xs">';
        html += text;
        if (type) {
          html += '<span class="ml-1 text-[10px] uppercase text-gray-500">' + type + '</span>';
        }
        html += '</span>';
      });
      html += '</div></div>';
    }

    if (data.sentiment) {
      html += '<div><h3 class="text-sm font-semibold text-gray-900 mb-1">Sentiment</h3>';
      const label = data.sentiment.sentiment_label || data.sentiment.overall || 'N/A';
      html += '<p class="text-sm text-gray-800 mb-1">' + label + '</p>';
    }

    if (Array.isArray(data.keywords) && data.keywords.length) {
      html += '<div><h3 class="text-sm font-semibold text-gray-900 mb-1">Keywords</h3>';
      html += '<div class="flex flex-wrap gap-1.5">';
      data.keywords.forEach(k => {
        html += '<span class="inline-flex items-center px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 text-xs">#' + String(k) + '</span>';
      });
      html += '</div></div>';
    }

    if (data.summary) {
      html += '<div><h3 class="text-sm font-semibold text-gray-900 mb-1">Summary</h3>';
      html += '<p class="text-sm text-gray-800 whitespace-pre-line">' + data.summary + '</p></div>';
    }

    html += '</div>';
    modalBody.innerHTML = html;
  }

  async function callSummarize(docId, title) {
    openModal('Summarize document', title, `
      <div class="flex items-center gap-2 text-gray-500 text-sm">
        <svg class="h-4 w-4 animate-spin text-emerald-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4l3-3-3-3v4a8 8 0 100 16v-4l-3 3 3 3v-4a8 8 0 01-8-8z"></path>
        </svg>
        <span>Generating summary…</span>
      </div>
    `);

    try {
      const res = await fetch('../actions/summarize_document.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ documentId: docId, fileName: title })
      });
      const data = await res.json().catch(() => null);
      renderSummaryResult(data);
    } catch (e) {
      modalBody.innerHTML = '<p class="text-sm text-red-600">Error calling AI service. Please try again later.</p>';
    }
  }

  async function callAnalyze(docId, title) {
    openModal('Analyze document', title, `
      <div class="flex items-center gap-2 text-gray-500 text-sm">
        <svg class="h-4 w-4 animate-spin text-sky-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4l3-3-3-3v4a8 8 0 100 16v-4l-3 3 3 3v-4a8 8 0 01-8-8z"></path>
        </svg>
        <span>Analyzing document (entities, sentiment, keywords)…</span>
      </div>
    `);

    try {
      const res = await fetch('../actions/analyze_document.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ documentId: docId, analysisType: 'full' })
      });
      const data = await res.json().catch(() => null);
      renderAnalysisResult(data);
    } catch (e) {
      modalBody.innerHTML = '<p class="text-sm text-red-600">Error calling AI service. Please try again later.</p>';
    }
  }

  // Wire buttons
  document.querySelectorAll('.ai-btn-summarize').forEach(btn => {
    btn.addEventListener('click', () => {
      const docId = parseInt(btn.dataset.docId, 10);
      const title = btn.dataset.docTitle || 'Document';
      if (!docId) return;
      callSummarize(docId, title);
    });
  });

  document.querySelectorAll('.ai-btn-analyze').forEach(btn => {
    btn.addEventListener('click', () => {
      const docId = parseInt(btn.dataset.docId, 10);
      const title = btn.dataset.docTitle || 'Document';
      if (!docId) return;
      callAnalyze(docId, title);
    });
  });

  // Initial filter
  applyFilters();
})();
</script>

