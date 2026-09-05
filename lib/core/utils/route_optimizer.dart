import 'dart:convert';
import 'package:http/http.dart' as http;

class RouteOptimizer {
  /// OSRM Table API kullanarak noktalar arası GERÇEK SÜRÜŞ MESAFELERİNİ çeker
  /// ve Brute-Force (N<=10) veya NN+2-opt (N>10) kullanarak MESAFESİ (KİLOMETRESİ) en kısa sıralamayı bulur.
  static Future<List<Map<String, dynamic>>> optimizeWithMatrix(List<Map<String, dynamic>> points) async {
    if (points.length <= 3) return points;

    // 1. Koordinatları OSRM formatına çevir (lon,lat;lon,lat...)
    String coords = points.map((p) => '${p['lon']},${p['lat']}').join(';');
    
    // 2. Table API'den MESAFE matrisini çek (annotations=distance)
    final url = Uri.parse('https://router.project-osrm.org/table/v1/driving/$coords?annotations=distance');
    final response = await http.get(url, headers: {'User-Agent': 'DaytrackApp/1.0'});

    if (response.statusCode != 200) {
      throw Exception('OSRM table error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['code'] != 'Ok') {
      throw Exception('OSRM returned non-Ok code: ${data['code']}');
    }

    // distances matrix: i'den j'ye gitme mesafesi (metre)
    // Not: annotations=distance kullandığımız için 'distances' dizisi döner.
    List<dynamic> distancesRaw = data['distances'];
    List<List<double>> matrix = [];
    
    for (int i = 0; i < distancesRaw.length; i++) {
      List<double> row = [];
      for (int j = 0; j < distancesRaw[i].length; j++) {
        var val = distancesRaw[i][j];
        if (val == null) {
          row.add(double.infinity);
        } else {
          row.add((val as num).toDouble());
        }
      }
      matrix.add(row);
    }

    // 3. TSP Çözümü (En Kısa Mesafe)
    // 0: Start, N-1: End. Biz 1 ile N-2 arasındaki (stops) elemanların sırasını bulacağız.
    final int n = points.length;
    List<int> stopIndices = List.generate(n - 2, (index) => index + 1);
    
    List<int> bestOrder = [];

    // Durak sayısı 8 veya daha az ise (Toplam 10 nokta), Brute Force kesin çözüm.
    // 8! = 40,320 iterasyon. Dart'ta mili-saniyeler sürer.
    if (stopIndices.length <= 8) {
      double minDistance = double.infinity;
      
      void permute(List<int> arr, int k) {
        if (k == arr.length) {
          double currentDist = _calculateTotal(matrix, [0, ...arr, n - 1]);
          if (currentDist < minDistance) {
            minDistance = currentDist;
            bestOrder = List.from(arr);
          }
          return;
        }
        for (int i = k; i < arr.length; i++) {
          int temp = arr[i];
          arr[i] = arr[k];
          arr[k] = temp;
          
          permute(arr, k + 1);
          
          temp = arr[i];
          arr[i] = arr[k];
          arr[k] = temp;
        }
      }
      
      permute(stopIndices, 0);
    } else {
      // 8'den fazlaysa Nearest Neighbor + 2-opt
      List<int> currentOrder = [];
      List<int> unvisited = List.from(stopIndices);
      int currentPoint = 0; // Start at 0

      while (unvisited.isNotEmpty) {
        double minVal = double.infinity;
        int nearestIdx = -1;
        int nearestVal = -1;

        for (int i = 0; i < unvisited.length; i++) {
          double dist = matrix[currentPoint][unvisited[i]];
          if (dist < minVal) {
            minVal = dist;
            nearestIdx = i;
            nearestVal = unvisited[i];
          }
        }

        currentOrder.add(nearestVal);
        currentPoint = nearestVal;
        unvisited.removeAt(nearestIdx);
      }

      List<int> path = [0, ...currentOrder, n - 1];
      
      bool improved = true;
      while (improved) {
        improved = false;
        for (int i = 1; i < path.length - 2; i++) {
          for (int k = i + 1; k < path.length - 1; k++) {
            List<int> newPath = _twoOptSwap(path, i, k);
            double oldDist = _calculateTotal(matrix, path);
            double newDist = _calculateTotal(matrix, newPath);

            if (newDist < oldDist) {
              path = newPath;
              improved = true;
            }
          }
        }
      }
      // Extract middle part
      bestOrder = path.sublist(1, path.length - 1);
    }

    // 4. En iyi sırayı oluştur ve geri dön
    List<Map<String, dynamic>> optimizedPoints = [points.first];
    for (int idx in bestOrder) {
      optimizedPoints.add(points[idx]);
    }
    optimizedPoints.add(points.last);

    return optimizedPoints;
  }

  static double _calculateTotal(List<List<double>> matrix, List<int> path) {
    double total = 0.0;
    for (int i = 0; i < path.length - 1; i++) {
      total += matrix[path[i]][path[i+1]];
    }
    return total;
  }

  static List<int> _twoOptSwap(List<int> path, int i, int k) {
    List<int> newPath = [];
    newPath.addAll(path.sublist(0, i));
    
    List<int> reversedSegment = path.sublist(i, k + 1).reversed.toList();
    newPath.addAll(reversedSegment);
    
    newPath.addAll(path.sublist(k + 1));
    return newPath;
  }
}
