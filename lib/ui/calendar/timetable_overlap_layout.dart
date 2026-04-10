/// Horizontal lane assignment for overlapping intervals in a day timetable.
library;

/// Result of [layoutTimetableSegmentsForDay] for one segment.
class TimetableSegmentLaneLayout {
  const TimetableSegmentLaneLayout({
    required this.column,
    required this.columnCount,
  });

  /// Zero-based column within the segment's overlap cluster.
  final int column;

  /// Number of columns used by that cluster (width divisor).
  final int columnCount;
}

bool _intervalsOverlap(
  ({DateTime start, DateTime end}) a,
  ({DateTime start, DateTime end}) b,
) =>
    a.start.isBefore(b.end) && b.start.isBefore(a.end);

/// Assigns columns so overlapping intervals sit side-by-side; independent
/// overlap clusters do not share a column count.
List<TimetableSegmentLaneLayout> layoutTimetableSegmentsForDay(
  List<({DateTime start, DateTime end})> segments,
) {
  final n = segments.length;
  if (n == 0) return [];

  final adj = List.generate(n, (_) => <int>[]);
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      if (_intervalsOverlap(segments[i], segments[j])) {
        adj[i].add(j);
        adj[j].add(i);
      }
    }
  }

  final visited = List.filled(n, false);
  final componentOf = List.filled(n, 0);
  var compId = 0;
  for (var start = 0; start < n; start++) {
    if (visited[start]) continue;
    final stack = <int>[start];
    visited[start] = true;
    while (stack.isNotEmpty) {
      final u = stack.removeLast();
      componentOf[u] = compId;
      for (final v in adj[u]) {
        if (!visited[v]) {
          visited[v] = true;
          stack.add(v);
        }
      }
    }
    compId++;
  }

  final byComponent = <int, List<int>>{};
  for (var i = 0; i < n; i++) {
    byComponent.putIfAbsent(componentOf[i], () => []).add(i);
  }

  final columnByIndex = List.filled(n, 0);
  final columnCountByIndex = List.filled(n, 1);

  for (final indices in byComponent.values) {
    indices.sort((a, b) {
      final c = segments[a].start.compareTo(segments[b].start);
      if (c != 0) return c;
      return segments[a].end.compareTo(segments[b].end);
    });

    final placed = <({int index, int column, DateTime start, DateTime end})>[];
    var maxColumn = -1;

    for (final idx in indices) {
      final seg = segments[idx];
      final taken = <int>{};
      for (final p in placed) {
        if (_intervalsOverlap(seg, (start: p.start, end: p.end))) {
          taken.add(p.column);
        }
      }
      var k = 0;
      while (taken.contains(k)) {
        k++;
      }
      placed.add((
        index: idx,
        column: k,
        start: seg.start,
        end: seg.end,
      ));
      if (k > maxColumn) maxColumn = k;
    }

    final count = maxColumn + 1;
    for (final p in placed) {
      columnByIndex[p.index] = p.column;
      columnCountByIndex[p.index] = count;
    }
  }

  return List.generate(
    n,
    (i) => TimetableSegmentLaneLayout(
      column: columnByIndex[i],
      columnCount: columnCountByIndex[i],
    ),
  );
}
