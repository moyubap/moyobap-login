import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // 선택된 맛집 인덱스를 추적
  int selectedRestaurantIndex = 0;

  // 맛집 정보를 저장하는 리스트
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

  // 현재 지도 확대/축소 상태를 추적
  double _scale = 1.0;
  final TransformationController _transformationController = TransformationController();

  // 맛집 선택 시 해당 맛집으로 인덱스를 업데이트
  void selectRestaurant(int index) {
    setState(() {
      selectedRestaurantIndex = index;
    });
  }

  // 확대 기능
  void zoomIn() {
    setState(() {
      _scale += 0.2;
      _transformationController.value = Matrix4.identity()..scale(_scale);
    });
  }

  // 축소 기능
  void zoomOut() {
    setState(() {
      _scale = (_scale - 0.2).clamp(1.0, 3.0); // 최소 1.0, 최대 3.0으로 제한
      _transformationController.value = Matrix4.identity()..scale(_scale);
    });
  }

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity()..scale(_scale);
  }

  @override
  Widget build(BuildContext context) {
    final selected = restaurantInfo[selectedRestaurantIndex]; // 선택된 맛집 정보

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue, // 상단 바 배경 색상
        centerTitle: true,
        title: const Text(
          '지도',
          style: TextStyle(fontWeight: FontWeight.bold), // 앱바 제목
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 지도 이미지 영역
                SizedBox(
                  height: 300,
                  child: InteractiveViewer(
                    panEnabled: true, // 지도 이동 가능 여부
                    minScale: 1.0, // 최소 확대 배율
                    maxScale: 3.0, // 최대 확대 배율
                    scaleEnabled: true, // 확대/축소 기능 활성화
                    transformationController: _transformationController,
                    child: Image.asset(
                      'assets/images/busanfoodmap.jpeg', // 지도 이미지 경로
                      fit: BoxFit.cover, // 이미지 크기 조정 방식
                    ),
                  ),
                ),
                // 확대/축소 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.zoom_in, size: 40), // 확대 아이콘
                      onPressed: zoomIn,
                    ),
                    IconButton(
                      icon: Icon(Icons.zoom_out, size: 40), // 축소 아이콘
                      onPressed: zoomOut,
                    ),
                  ],
                ),
              ],
            ),
            // 페이지뷰와 상세 정보
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: restaurantInfo.length, // 맛집 정보의 개수
                  onPageChanged: (index) => selectRestaurant(index), // 페이지 변경 시 맛집 선택
                  itemBuilder: (context, index) {
                    final info = restaurantInfo[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: RestaurantCard(
                        info: info, // 맛집 정보 전달
                        onMorePressed: () {
                          // 더 자세히 보기 버튼 클릭 시 상세 페이지로 이동
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
        borderRadius: BorderRadius.circular(16), // 카드의 둥근 모서리
      ),
      elevation: 3, // 카드 그림자
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info['name'], // 맛집 이름
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info['hours'], // 운영시간
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              info['description'], // 맛집 설명
              maxLines: 2, // 최대 2줄까지 표시
              overflow: TextOverflow.ellipsis, // 내용이 길면 생략 부호 표시
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  info['rating'], // 평점
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  '리뷰: ${info['reviewer']}', // 리뷰어 정보
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
                onPressed: onMorePressed, // '더 자세히 보기' 버튼 클릭 시 이벤트
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
      appBar: AppBar(title: Text(info['name'])), // 상세 페이지 제목은 맛집 이름
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/busanfoodmap.jpeg', fit: BoxFit.cover), // 상세 이미지
            const SizedBox(height: 16),
            Text('⏰ 운영시간: ${info['hours']}'), // 운영시간
            const SizedBox(height: 8),
            Text('⭐️ 평점: ${info['rating']}'), // 평점
            const SizedBox(height: 8),
            Text('💬 한줄평: ${info['description']}'), // 한줄평
            const SizedBox(height: 8),

            // 리뷰 목록 추가
            Text('📋 리뷰:'),
            for (var review in info['reviews']) ...[ // 각 리뷰 출력
              const SizedBox(height: 8),
              Text('“$review”'),
            ],
          ],
        ),
      ),
    );
  }
}
