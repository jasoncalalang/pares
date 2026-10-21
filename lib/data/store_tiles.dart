/// The stores offered on the "Where do you shop?" screen. Display names are
/// the short forms people say ("Robinsons", "S&R"); [id] is the catalog key
/// in `phStores`. Honest mockup rule: monograms, never retailer logos.
class StoreTile {
  const StoreTile({required this.id, required this.name, required this.monogram});

  final String id;
  final String name;
  final String monogram;
}

/// Supermarket chains, warehouse clubs and delivery: the annatto group.
const List<StoreTile> chainTiles = [
  StoreTile(id: 'sm-supermarket', name: 'SM Supermarket', monogram: 'SM'),
  StoreTile(id: 'puregold', name: 'Puregold', monogram: 'P'),
  StoreTile(id: 'savemore', name: 'Savemore', monogram: 'SM'),
  StoreTile(id: 'robinsons-supermarket', name: 'Robinsons', monogram: 'R'),
  StoreTile(id: 's-and-r', name: 'S&R', monogram: 'S&R'),
  StoreTile(id: 'landers', name: 'Landers', monogram: 'L'),
  StoreTile(id: 'waltermart', name: 'WalterMart', monogram: 'W'),
  StoreTile(id: 'grabmart', name: 'GrabMart', monogram: 'G'),
];

/// Local to the Philippines: the green group.
const List<StoreTile> localTiles = [
  StoreTile(id: 'palengke', name: 'Wet market', monogram: 'W'),
  StoreTile(id: 'sari-sari', name: 'Corner store', monogram: 'C'),
];
