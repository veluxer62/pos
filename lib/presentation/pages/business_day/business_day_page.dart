import 'package:flutter/material.dart';

/// 영업 시작이 필요한 경우 라우트 가드가 이 페이지로 리다이렉트한다.
class BusinessDayPage extends StatelessWidget {
  const BusinessDayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('영업 시작 / 마감')),
    );
  }
}
