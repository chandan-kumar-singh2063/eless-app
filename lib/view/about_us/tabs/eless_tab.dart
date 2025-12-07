import 'package:flutter/material.dart';

class ElessTab extends StatelessWidget {
  const ElessTab({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // Hero Image
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/eless.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ELESS Title
            Text(
              'ELESS',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Electrical Engineering Students Society',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 40),

            // About Section
            _buildSection(
              context,
              title: 'About Us',
              content:
                  'ELESS is a student-led innovation club dedicated to fostering creativity, technical excellence, and collaborative learning. We bring together passionate students to work on real-world projects, share knowledge, and build solutions that matter.',
            ),

            const SizedBox(height: 24),

            // What We Do Section
            _buildSection(
              context,
              title: 'What We Do',
              content:
                  'We organize workshops, hackathons, and project collaborations across various domains of Electrical Engineering like Power System and Control System. Our club provides a platform for students to learn new technologies, develop practical skills, and connect with like-minded peers.',
            ),

            const SizedBox(height: 24),

            // Mission Section with background
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'To empower students with hands-on experience, cultivate innovation, and create a supportive community where ideas transform into impactful projects.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Core Values Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Core Values',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildValueItem(
                    context,
                    Icons.lightbulb_outline,
                    'Innovation',
                    'Encouraging creative thinking and new ideas',
                  ),
                  _buildValueItem(
                    context,
                    Icons.star_outline,
                    'Excellence',
                    'Striving for quality in every project',
                  ),
                  _buildValueItem(
                    context,
                    Icons.people_outline,
                    'Collaboration',
                    'Building together as a team',
                  ),
                  _buildValueItem(
                    context,
                    Icons.trending_up,
                    'Growth',
                    'Continuous learning and development',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Activities Section
            _buildSection(
              context,
              title: 'Our Activities',
              content:
                  '• Monthly technical workshops and Virtual sessions\n• Semester projects and innovation challenges\n• Guest lectures from industry professionals\n• Peer mentoring and skill-sharing sessions',
            ),

            const SizedBox(height: 48),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.corporate_fare,
                    size: 32,
                    color: primaryColor.withOpacity(0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '© 2025 ELESS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All rights reserved',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
