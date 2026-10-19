import '../locale/currency.dart';

/// Kinds of place a Filipino household actually buys food. This deliberately
/// goes beyond supermarket chains: membership warehouse clubs, online/delivery
/// channels, the public wet market (palengke) and the neighbourhood sari-sari
/// store are all first-class here.
enum StoreType {
  supermarket,
  hypermarket,
  warehouseClub,
  convenience,
  online,
  wetMarket,
  sariSari,
}

/// Coarse island-group footprint for store pickers; refined to region/city
/// later.
enum PhRegionGroup { luzon, ncr, visayas, mindanao, nationwide }

/// A place to buy groceries.
class Store {
  const Store({
    required this.id,
    required this.name,
    required this.type,
    required this.regions,
    required this.online,
    required this.logoKey,
    this.parentGroup,
    this.currency = php,
  });

  /// Stable kebab-case id; used as a key everywhere and in analytics.
  final String id;
  final String name;
  final StoreType type;

  /// Parent retail group, where confidently known; otherwise null.
  final String? parentGroup;

  /// Coarse availability footprint.
  final List<PhRegionGroup> regions;

  /// True when the store offers online ordering / delivery of groceries.
  final bool online;

  final Currency currency;

  /// Supabase `store-logos/` object key (assets are not committed here).
  final String logoKey;
}

String _logo(String id) => 'store-logos/$id.png';

/// The Philippine store catalog.
///
/// SEED DATA — chain names are widely known and stable, but parent-company
/// ownership and regional availability still need a data-team review before
/// this is treated as authoritative.
final List<Store> phStores = List.unmodifiable([
  // ---- Supermarkets ----
  Store(id: 'sm-supermarket', name: 'SM Supermarket', type: StoreType.supermarket, parentGroup: 'SM Retail', regions: [PhRegionGroup.nationwide], online: true, logoKey: _logo('sm-supermarket')),
  Store(id: 'savemore', name: 'Savemore Market', type: StoreType.supermarket, parentGroup: 'SM Retail', regions: [PhRegionGroup.nationwide], online: true, logoKey: _logo('savemore')),
  Store(id: 'puregold', name: 'Puregold', type: StoreType.supermarket, parentGroup: 'Puregold Price Club', regions: [PhRegionGroup.nationwide], online: true, logoKey: _logo('puregold')),
  Store(id: 'robinsons-supermarket', name: 'Robinsons Supermarket', type: StoreType.supermarket, parentGroup: 'Robinsons Retail', regions: [PhRegionGroup.nationwide], online: true, logoKey: _logo('robinsons-supermarket')),
  Store(id: 'waltermart', name: 'WalterMart Supermarket', type: StoreType.supermarket, regions: [PhRegionGroup.luzon, PhRegionGroup.ncr], online: true, logoKey: _logo('waltermart')),
  Store(id: 'metro-supermarket', name: 'Metro Supermarket', type: StoreType.supermarket, parentGroup: 'Metro Retail Stores Group', regions: [PhRegionGroup.visayas, PhRegionGroup.ncr], online: false, logoKey: _logo('metro-supermarket')),
  Store(id: 'rustans-supermarket', name: "Rustan's Supermarket", type: StoreType.supermarket, parentGroup: 'Robinsons Retail', regions: [PhRegionGroup.ncr], online: true, logoKey: _logo('rustans-supermarket')),
  Store(id: 'allday', name: 'AllDay Supermarket', type: StoreType.supermarket, parentGroup: 'Vista Group', regions: [PhRegionGroup.luzon, PhRegionGroup.ncr], online: false, logoKey: _logo('allday')),

  // ---- Hypermarkets ----
  Store(id: 'sm-hypermarket', name: 'SM Hypermarket', type: StoreType.hypermarket, parentGroup: 'SM Retail', regions: [PhRegionGroup.nationwide], online: true, logoKey: _logo('sm-hypermarket')),
  Store(id: 'super-metro', name: 'Super Metro', type: StoreType.hypermarket, parentGroup: 'Metro Retail Stores Group', regions: [PhRegionGroup.visayas], online: false, logoKey: _logo('super-metro')),

  // ---- Membership warehouse clubs ----
  Store(id: 's-and-r', name: 'S&R Membership Shopping', type: StoreType.warehouseClub, parentGroup: 'Kareila / Cosco Capital', regions: [PhRegionGroup.nationwide], online: true, logoKey: _logo('s-and-r')),
  Store(id: 'landers', name: 'Landers Superstore', type: StoreType.warehouseClub, parentGroup: 'Robinsons Retail', regions: [PhRegionGroup.luzon, PhRegionGroup.ncr, PhRegionGroup.visayas], online: true, logoKey: _logo('landers')),

  // ---- Convenience ----
  Store(id: '7-eleven', name: '7-Eleven', type: StoreType.convenience, parentGroup: 'Philippine Seven', regions: [PhRegionGroup.nationwide], online: false, logoKey: _logo('7-eleven')),
  Store(id: 'alfamart', name: 'Alfamart', type: StoreType.convenience, regions: [PhRegionGroup.luzon, PhRegionGroup.ncr], online: false, logoKey: _logo('alfamart')),
  Store(id: 'ministop', name: 'Ministop', type: StoreType.convenience, parentGroup: 'Robinsons Retail', regions: [PhRegionGroup.ncr, PhRegionGroup.luzon], online: false, logoKey: _logo('ministop')),

  // ---- Online / delivery channels ----
  Store(id: 'metromart', name: 'MetroMart', type: StoreType.online, regions: [PhRegionGroup.ncr, PhRegionGroup.luzon, PhRegionGroup.visayas], online: true, logoKey: _logo('metromart')),
  Store(id: 'grabmart', name: 'GrabMart', type: StoreType.online, parentGroup: 'Grab', regions: [PhRegionGroup.nationwide], online: true, logoKey: _logo('grabmart')),
  Store(id: 'pushkart', name: 'Pushkart', type: StoreType.online, regions: [PhRegionGroup.ncr], online: true, logoKey: _logo('pushkart')),

  // ---- The PH reality NA apps ignore ----
  Store(id: 'palengke', name: 'Palengke (Wet Market)', type: StoreType.wetMarket, regions: [PhRegionGroup.nationwide], online: false, logoKey: _logo('palengke')),
  Store(id: 'sari-sari', name: 'Sari-sari Store', type: StoreType.sariSari, regions: [PhRegionGroup.nationwide], online: false, logoKey: _logo('sari-sari')),
]);

final Map<String, Store> _byId = {for (final s in phStores) s.id: s};

/// Look up a store by id; null if it isn't in the catalog.
Store? storeById(String id) => _byId[id];

/// All stores of a given type, in catalog order.
List<Store> storesByType(StoreType type) =>
    phStores.where((s) => s.type == type).toList();

/// Stores that offer online ordering / delivery.
List<Store> onlineStores() => phStores.where((s) => s.online).toList();
