import 'dart:math';

class RouteOptimizer {
  /// Sabit dünya yarıçapı (km cinsinden)
  static const double earthRadiusKm = 6371.0;

  /// İki koordinat (enlem, boylam) arasındaki kuş uçuşu (Haversine) mesafeyi km olarak hesaplar.
  static double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
        
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Noktalar arası mesafe kullanarak toplam tur mesafesini hesaplar.
  static double _calculateTotalDistance(List<Map<String, dynamic>> path) {
    double total = 0.0;
    for (int i = 0; i < path.length - 1; i++) {
      total += _haversineDistance(
        path[i]['lat'], path[i]['lon'],
        path[i+1]['lat'], path[i+1]['lon']
      );
    }
    return total;
  }

  /// Başlangıç ve bitiş noktası sabit olmak şartıyla aradaki noktaları
  /// en kısa mesafeye göre sıralar.
  /// Start ve End noktalarının Listede her zaman ilk ve son eleman olması beklenir.
  static List<Map<String, dynamic>> optimize(List<Map<String, dynamic>> points) {
    if (points.length <= 3) return points;

    final startPoint = points.first;
    final endPoint = points.last;
    List<Map<String, dynamic>> stops = points.sublist(1, points.length - 1);

    // 1. Adım: Nearest Neighbor Algorithm (En Yakın Komşu)
    List<Map<String, dynamic>> orderedStops = [];
    List<Map<String, dynamic>> unvisitedStops = List.from(stops);
    
    Map<String, dynamic> currentPoint = startPoint;
    
    while (unvisitedStops.isNotEmpty) {
      double minDistance = double.infinity;
      int nearestIndex = -1;

      for (int i = 0; i < unvisitedStops.length; i++) {
        final dist = _haversineDistance(
          currentPoint['lat'], currentPoint['lon'],
          unvisitedStops[i]['lat'], unvisitedStops[i]['lon']
        );
        if (dist < minDistance) {
          minDistance = dist;
          nearestIndex = i;
        }
      }

      currentPoint = unvisitedStops[nearestIndex];
      orderedStops.add(currentPoint);
      unvisitedStops.removeAt(nearestIndex);
    }

    // Başlangıç, sıralanmış duraklar ve bitişten oluşan rotayı oluştur.
    List<Map<String, dynamic>> currentPath = [startPoint, ...orderedStops, endPoint];

    // 2. Adım: 2-opt Local Search Algorithm (Sadeleştirme)
    // Rota üzerinde herhangi iki bağı (edge) koparıp çapraz bağlayarak mesafe kısalıyor mu diye bakar.
    bool improved = true;
    while (improved) {
      improved = false;
      for (int i = 1; i < currentPath.length - 2; i++) {
        for (int k = i + 1; k < currentPath.length - 1; k++) {
          final newPath = _twoOptSwap(currentPath, i, k);
          final oldDist = _calculateTotalDistance(currentPath);
          final newDist = _calculateTotalDistance(newPath);

          if (newDist < oldDist) {
            currentPath = newPath;
            improved = true;
          }
        }
      }
    }

    return currentPath;
  }

  /// 2-opt Swap metodu
  static List<Map<String, dynamic>> _twoOptSwap(
    List<Map<String, dynamic>> path, int i, int k
  ) {
    List<Map<String, dynamic>> newPath = [];
    // 1. take route[0] to route[i-1] and add them in order to new_route
    newPath.addAll(path.sublist(0, i));
    
    // 2. take route[i] to route[k] and add them in reverse order to new_route
    List<Map<String, dynamic>> reversedSegment = path.sublist(i, k + 1).reversed.toList();
    newPath.addAll(reversedSegment);
    
    // 3. take route[k+1] to end and add them in order to new_route
    newPath.addAll(path.sublist(k + 1));
    
    return newPath;
  }
}
