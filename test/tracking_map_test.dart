import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/features/orders/presentation/widgets/tracking_map.dart';

void main() {
  group('TrackingMapPoint.fromPlace', () {
    test('parses valid numeric and string coordinates', () {
      expect(
        TrackingMapPoint.fromPlace({'latitud': 13.69, 'longitud': '-89.21'}),
        const TrackingMapPoint(latitude: 13.69, longitude: -89.21),
      );
    });

    test('returns null for missing or out-of-range coordinates', () {
      expect(TrackingMapPoint.fromPlace(null), isNull);
      expect(TrackingMapPoint.fromPlace({'latitud': 13.69}), isNull);
      expect(
        TrackingMapPoint.fromPlace({'latitud': 91, 'longitud': -89.21}),
        isNull,
      );
      expect(
        TrackingMapPoint.fromPlace({'latitud': 13.69, 'longitud': -181}),
        isNull,
      );
    });
  });
}
