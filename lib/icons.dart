import 'package:flutter/material.dart';
import 'dashboard.dart';

class IconsPage extends StatefulWidget {
  const IconsPage({super.key});

  @override
  State<IconsPage> createState() => _IconsPageState();
}

class Item {
  final String icon;
  final String name;
  final int value;
  final String status;
  final String detail;
  final Widget? page;

  Item(this.icon, this.name, this.value, this.status, this.detail, this.page);
}

class _IconsPageState extends State<IconsPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  final List<Item> items = [
    Item('🧯','Fire extinguishers',95,'green','All OK', const DashboardPage()),
    Item('🧵','Hose reels',98,'green','OK', null),
    Item('🛢️','Drum hose reels',100,'green','OK', null),
    Item('🚒','Hydrant points',100,'green','OK', null),
    Item('🚿','Sprinkler system',100,'green','OK', null),

    Item('🔔','Fire alarm panels',100,'green','OK', null),
    Item('🌫️','Smoke detectors',95,'green','OK', null),
    Item('🛒','Fire trolley',100,'green','OK', null),
    Item('🚪','Emergency exits',100,'green','OK', null),
    Item('💡','Emergency lighting',97,'green','OK', null),

    Item('📢','PA system',100,'green','OK', null),
    Item('📡','Wind sock',100,'green','OK', null),
    Item('🫁','SCBA units',66,'amber','Check', null),
    Item('🚑','Ambulance',50,'red','Needs attention', null),
    Item('🏥','First aid',93,'green','OK', null),

    Item('🚰','Emergency shower',100,'green','OK', null),
    Item('👀','Eye wash',87,'amber','Check', null),
    Item('⚗️','Spill kits',90,'green','OK', null),
    Item('🛁','Chemical shower',100,'green','OK', null),
    Item('🦺','PPE cabinets',91,'green','OK', null),

    Item('☁️','CO₂ system',100,'green','OK', null),
    Item('⚠️','Signage',96,'green','OK', null),
    Item('📞','Emergency comm.',80,'amber','Check', null),
    Item('🧲','Fire blankets',100,'green','OK', null),
    Item('📍','Muster points',100,'green','OK', null),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color getColor(String status) {
    switch (status) {
      case 'green':
        return Colors.green;
      case 'amber':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],

      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(10),

          // 👇 THIS MAKES IT LOOK LIKE MOBILE HOME SCREEN
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 👈 phone-like layout
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),

          itemCount: items.length,

          itemBuilder: (context, index) {
            final item = items[index];
            bool isRed = item.status == 'red';

            return GestureDetector(
              onTap: () {
                if (item.page != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item.page!),
                  );
                }
              },

              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double opacity =
                  isRed ? (_controller.value * 0.6 + 0.4) : 1.0;

                  return Opacity(
                    opacity: opacity,
                    child: child,
                  );
                },

                child: Container(
                  decoration: BoxDecoration(
                    color: getColor(item.status).withOpacity(0.2),
                    border: Border.all(color: getColor(item.status)),
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.icon,
                          style: const TextStyle(fontSize: 26)),

                      const SizedBox(height: 6),

                      Text(
                        item.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}