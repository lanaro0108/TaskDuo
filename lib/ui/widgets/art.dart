import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';

class Art extends StatelessWidget {
  const Art(this.name, {super.key, this.size = 40});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/art/$name.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
  );
}

class Avatar extends StatelessWidget {
  const Avatar(this.member, {super.key, this.size = 40, this.ring = false});
  final Member member;
  final double size;
  final bool ring;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Avatar de ${member.name}',
    image: true,
    child: Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring ? 3 : 1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Palette.of(context).surface,
        border: Border.all(
          color: Brand.lilac.withValues(alpha: .35),
          width: ring ? 2 : 1,
        ),
      ),
      child: ClipOval(
        child: CustomPaint(
          painter: _PortraitPainter(member.avatar),
          size: Size.square(size),
        ),
      ),
    ),
  );
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter(this.variant);
  final int variant;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100);
    final p = Paint()..isAntiAlias = true;
    final bg = [
      const Color(0xffcbb5ff),
      const Color(0xffb8dcff),
      const Color(0xffa5e9cf),
      const Color(0xffffc2d6),
    ][variant % 4];
    p.shader = RadialGradient(colors: [Color.lerp(bg, Colors.white, .4)!, bg])
        .createShader(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawCircle(const Offset(50, 50), 50, p);
    p.shader = null;
    final hair = variant % 2 == 0
        ? const Color(0xff693e31)
        : const Color(0xff3c2c32);
    p.color = hair;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, 12, 64, 87),
        const Radius.circular(32),
      ),
      p,
    );
    p.color = variant == 2 ? const Color(0xff659cdd) : const Color(0xffab79e8);
    canvas.drawOval(const Rect.fromLTWH(20, 76, 64, 48), p);
    p.color = const Color(0xffefb18a);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(43, 63, 17, 21),
        const Radius.circular(7),
      ),
      p,
    );
    p.color = const Color(0xfffee3cc);
    canvas.drawOval(const Rect.fromLTWH(41, 75, 21, 9), p);
    p.color = const Color(0xfff8c49e);
    canvas.drawOval(const Rect.fromLTWH(25, 39, 12, 17), p);
    canvas.drawOval(const Rect.fromLTWH(69, 39, 12, 17), p);
    p.shader = const LinearGradient(
      colors: [Color(0xffffd9b5), Color(0xffefb28d)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(const Rect.fromLTWH(31, 25, 44, 47));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 23, 45, 51),
        const Radius.circular(23),
      ),
      p,
    );
    p.shader = null;
    p.color = hair;
    final fringe = Path()
      ..moveTo(24, 45)
      ..cubicTo(24, 8, 70, 4, 79, 33)
      ..lineTo(76, 49)
      ..cubicTo(66, 40, 61, 29, 59, 26)
      ..cubicTo(49, 41, 39, 43, 24, 45);
    canvas.drawPath(fringe, p);
    p.color = const Color(0xff8c5740);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 2.2;
    p.strokeCap = StrokeCap.round;
    canvas.drawArc(
      const Rect.fromLTWH(36, 42, 10, 5),
      math.pi,
      math.pi,
      false,
      p,
    );
    canvas.drawArc(
      const Rect.fromLTWH(59, 42, 10, 5),
      math.pi,
      math.pi,
      false,
      p,
    );
    p.style = PaintingStyle.fill;
    p.color = const Color(0xff362a32);
    canvas.drawOval(const Rect.fromLTWH(39, 46, 4.5, 7), p);
    canvas.drawOval(const Rect.fromLTWH(61, 46, 4.5, 7), p);
    p.color = Colors.white;
    canvas.drawCircle(const Offset(40, 47), 1, p);
    canvas.drawCircle(const Offset(62, 47), 1, p);
    p.color = const Color(0xffe88e87).withValues(alpha: .55);
    canvas.drawOval(const Rect.fromLTWH(33, 53, 10, 5), p);
    canvas.drawOval(const Rect.fromLTWH(64, 53, 10, 5), p);
    p.color = const Color(0xffa5514c);
    final smile = Path()
      ..moveTo(44, 59)
      ..quadraticBezierTo(53, 65, 62, 58)
      ..quadraticBezierTo(56, 73, 47, 64)
      ..close();
    canvas.drawPath(smile, p);
    p.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(47, 60, 11, 2.5),
        const Radius.circular(1),
      ),
      p,
    );
    p.color = const Color(0xff98644a).withValues(alpha: .4);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 2;
    canvas.drawArc(const Rect.fromLTWH(22, 22, 56, 67), 3, 1.8, false, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PortraitPainter oldDelegate) =>
      oldDelegate.variant != variant;
}

class HouseMascot extends StatelessWidget {
  const HouseMascot({super.key, this.size = 110});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _HousePainter()),
  );
}

class _HousePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 120);
    final p = Paint()..isAntiAlias = true;
    p.color = Brand.purple.withValues(alpha: .12);
    c.drawOval(const Rect.fromLTWH(19, 100, 89, 12), p);
    p.shader = const LinearGradient(
      colors: [Color(0xffe8d9ff), Color(0xffb4a4ff)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(const Rect.fromLTWH(22, 40, 79, 65));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(25, 43, 71, 61),
        const Radius.circular(10),
      ),
      p,
    );
    p.shader = null;
    p.color = const Color(0xffa18bef);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(80, 22, 13, 29),
        const Radius.circular(4),
      ),
      p,
    );
    final roof = Path()
      ..moveTo(14, 53)
      ..lineTo(53, 19)
      ..quadraticBezierTo(59, 14, 66, 20)
      ..lineTo(106, 53)
      ..quadraticBezierTo(111, 60, 102, 64)
      ..lineTo(61, 31)
      ..lineTo(21, 64)
      ..quadraticBezierTo(10, 64, 14, 53);
    p.shader = const LinearGradient(
      colors: [Color(0xffa684f4), Color(0xff8279ef)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(const Rect.fromLTWH(12, 18, 97, 47));
    c.drawPath(roof, p);
    p.shader = null;
    p.color = const Color(0xff7571d4);
    c.drawOval(const Rect.fromLTWH(43, 63, 6, 9), p);
    c.drawOval(const Rect.fromLTWH(74, 63, 6, 9), p);
    p.color = Colors.white;
    c.drawCircle(const Offset(45, 65), 1.2, p);
    c.drawCircle(const Offset(76, 65), 1.2, p);
    p.color = const Color(0xffefb1d9);
    c.drawOval(const Rect.fromLTWH(32, 75, 17, 7), p);
    c.drawOval(const Rect.fromLTWH(78, 75, 17, 7), p);
    p.color = const Color(0xff7465c5);
    p.style = PaintingStyle.stroke;
    p.strokeCap = StrokeCap.round;
    p.strokeWidth = 3;
    c.drawArc(const Rect.fromLTWH(54, 72, 15, 11), 0, math.pi, false, p);
    p.style = PaintingStyle.fill;
    p.color = const Color(0xff9b8ee5);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(56, 89, 15, 16),
        const Radius.circular(5),
      ),
      p,
    );
    p.color = const Color(0xffffd468);
    _star(c, const Offset(23, 21), 10, p);
    p.color = const Color(0xffffe9a0);
    _star(c, const Offset(9, 35), 6, p);
    p.color = const Color(0xffc3a4ff);
    _star(c, const Offset(104, 29), 6, p);
    c.restore();
  }

  void _star(Canvas c, Offset o, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? r : r * .47;
      final pt = o + Offset(math.cos(a) * radius, math.sin(a) * radius);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(path..close(), p);
  }

  @override
  bool shouldRepaint(_HousePainter oldDelegate) => false;
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.home_rounded, color: Brand.blue, size: size),
        Positioned(
          bottom: size * .17,
          child: Icon(
            Icons.favorite_rounded,
            color: Brand.lilac,
            size: size * .35,
          ),
        ),
      ],
    ),
  );
}
