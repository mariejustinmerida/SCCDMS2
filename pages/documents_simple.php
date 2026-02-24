<?php
require_once __DIR__ . '/../includes/config.php';

if (!isset($_SESSION['user_id'])) {
    echo "<div class='bg-white rounded-xl shadow p-6'><p class='text-red-600'>You must be logged in to view documents.</p></div>";
    return;
}

$sql = "SELECT d.document_id, d.title, d.status, d.created_at, d.updated_at, dt.type_name
        FROM documents d
        LEFT JOIN document_types dt ON d.type_id = dt.type_id
        ORDER BY d.updated_at DESC
        LIMIT 100";

$result = $conn->query($sql);
?>

<div class="bg-white rounded-xl shadow p-6">
  <div class="flex items-center justify-between mb-4">
    <h1 class="text-2xl font-bold text-gray-800">Documents (simple view)</h1>
    <p class="text-sm text-gray-500">Showing latest 100 documents</p>
  </div>

  <?php if ($result && $result->num_rows > 0): ?>
    <div class="overflow-x-auto">
      <table class="min-w-full text-sm">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Title</th>
            <th class="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Type</th>
            <th class="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
            <th class="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Created</th>
            <th class="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Last Updated</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <?php while ($row = $result->fetch_assoc()): ?>
            <?php
              $title = $row['title'] ?: 'Untitled';
              $type = $row['type_name'] ?: 'N/A';
              $status = $row['status'] ?: 'draft';
              $created = $row['created_at'] ?: '';
              $updated = $row['updated_at'] ?: '';

              $statusLabel = strtoupper($status);
              $statusClasses = 'bg-gray-100 text-gray-800';
              if ($status === 'approved') {
                  $statusClasses = 'bg-green-100 text-green-800';
              } elseif ($status === 'pending') {
                  $statusClasses = 'bg-yellow-100 text-yellow-800';
              } elseif ($status === 'rejected') {
                  $statusClasses = 'bg-red-100 text-red-800';
              } elseif ($status === 'revision' || $status === 'revision_requested') {
                  $statusClasses = 'bg-purple-100 text-purple-800';
              }
            ?>
            <tr class="hover:bg-gray-50">
              <td class="px-3 py-2 whitespace-nowrap">
                <a href="?page=view_document&id=<?php echo (int)$row['document_id']; ?>" class="text-blue-600 hover:underline">
                  <?php echo htmlspecialchars($title, ENT_QUOTES, 'UTF-8'); ?>
                </a>
              </td>
              <td class="px-3 py-2 whitespace-nowrap text-gray-700">
                <?php echo htmlspecialchars($type, ENT_QUOTES, 'UTF-8'); ?>
              </td>
              <td class="px-3 py-2 whitespace-nowrap">
                <span class="inline-flex px-2 py-1 text-xs font-medium rounded-full <?php echo $statusClasses; ?>">
                  <?php echo htmlspecialchars($statusLabel, ENT_QUOTES, 'UTF-8'); ?>
                </span>
              </td>
              <td class="px-3 py-2 whitespace-nowrap text-gray-600 text-xs">
                <?php echo htmlspecialchars($created, ENT_QUOTES, 'UTF-8'); ?>
              </td>
              <td class="px-3 py-2 whitespace-nowrap text-gray-600 text-xs">
                <?php echo htmlspecialchars($updated, ENT_QUOTES, 'UTF-8'); ?>
              </td>
            </tr>
          <?php endwhile; ?>
        </tbody>
      </table>
    </div>
  <?php else: ?>
    <p class="text-gray-500">No documents found.</p>
  <?php endif; ?>
</div>

