import 'package:flutter/material.dart';

class PullToRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;

  const PullToRefreshWrapper({required this.child, this.onRefresh, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      color: Colors.lightBlueAccent,
      backgroundColor: const Color(0xFF0D0B2D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height + 1,
          child: child,
        ),
      ),
    );
  }
}
