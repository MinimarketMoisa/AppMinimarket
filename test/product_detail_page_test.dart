import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/core/network/dio_client.dart';
import 'package:minimarket/core/network/mock_api_interceptor.dart';
import 'package:minimarket/features/catalog/presentation/pages/product_detail_page.dart';

void main() {
  testWidgets('shows product details and API stock after opening a product', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://mock.minimarket.test'))
      ..interceptors.add(MockApiInterceptor());
    addTearDown(dio.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const MaterialApp(home: ProductDetailPage(productoId: 1)),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.text('Coca-Cola 600ml'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('Disponibilidad por sucursal'), findsOneWidget);
    expect(find.text('Agregar al carrito'), findsOneWidget);
  });
}
