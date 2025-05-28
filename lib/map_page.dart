import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int selectedRestaurantIndex = 0;

  final List<Map<String, dynamic>> restaurantInfo = [
    {
      'name': '곰탕의 달인',
      'lat': 35.1796,
      'lng': 129.0756,
      'hours': '15:00 - 23:00',
      'description': '건실한 서비스와 깊은 맛.',
      'reviewer': '쩝쩝석사',
      'rating': '⭐️ 4.8',
      'reviews': [
        '맛있고 든든한 곰탕! 한 그릇으로 배가 부르고 행복해집니다.',
        '친절한 서비스가 인상적이었어요. 다시 방문할게요!',
        '여기 곰탕 정말 맛있습니다. 고기와 국물의 조화가 최고!',
      ],
    },
    {
      'name': '마루식당',
      'lat': 35.1802,
      'lng': 129.0761,
      'hours': '11:30 - 22:00',
      'description': '싱싱한 재료를 사용한 회덮밥이 유명.',
      'reviewer': '서면역 스시러버',
      'rating': '⭐️ 4.5',
      'reviews': [
        '회덮밥이 신선하고 맛있어요. 항상 기대됩니다.',
        '회덮밥을 먹으러 여기 자주 와요. 맛있고 신선합니다.',
        '가격 대비 만족도가 높아요. 추천합니다.',
      ],
    },
  ];

  GoogleMapController? _mapController;

  void selectRestaurant(int index) {
    setState(() {
      selectedRestaurantIndex = index;
    });

    final newLatLng = LatLng(
      restaurantInfo[index]['lat'],
      restaurantInfo[index]['lng'],
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newLatLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = restaurantInfo[selectedRestaurantIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
        title: const Text(
          '지도',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    selected['lat'],
                    selected['lng'],
                  ),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('selected'),
                    position: LatLng(
                      selected['lat'],
                      selected['lng'],
                    ),
                    infoWindow: InfoWindow(
                      title: selected['name'],
                    ),
                  ),
                },
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: restaurantInfo.length,
                  onPageChanged: (index) => selectRestaurant(index),
                  itemBuilder: (context, index) {
                    final info = restaurantInfo[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: RestaurantCard(
                        info: info,
                        onMorePressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPage(info: info),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> info;
  final VoidCallback onMorePressed;

  const RestaurantCard({
    super.key,
    required this.info,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info['hours'],
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              info['description'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  info['rating'],
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  '리뷰: ${info['reviewer']}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: onMorePressed,
                child: const Text('더 자세히 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Map<String, dynamic> info;

  const DetailPage({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(info['name'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/부산 맛집 맵.jpeg', fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text('⏰ 운영시간: ${info['hours']}'),
            const SizedBox(height: 8),
            Text('⭐️ 평점: ${info['rating']}'),
            const SizedBox(height: 8),
            Text('💬 한줄평: ${info['description']}'),
            const SizedBox(height: 8),
            Text('📋 리뷰:'),
            for (var review in info['reviews']) ...[
              const SizedBox(height: 8),
              Text('“$review”'),
            ],
          ],
        ),
      ),
    );
  }
}