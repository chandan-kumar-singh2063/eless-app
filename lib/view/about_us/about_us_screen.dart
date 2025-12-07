import 'package:flutter/material.dart';
import 'package:eless/view/about_us/tabs/eless_tab.dart';
import 'package:eless/view/about_us/tabs/developer_info_tab.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xfff2f2f2),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'About Us',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: TabBar(
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 3,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'About ELESS'),
              Tab(text: "Developer's Info"),
            ],
          ),
        ),
        body: const TabBarView(children: [ElessTab(), DeveloperInfoTab()]),
      ),
    );
  }
}
