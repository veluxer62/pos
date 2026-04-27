import 'package:pos/core/di/providers.dart';
import 'package:pos/domain/entities/menu_item.dart';
import 'package:pos/domain/entities/seat.dart';
import 'package:pos/domain/usecases/menu_item/create_menu_item_use_case.dart';
import 'package:pos/domain/usecases/menu_item/delete_menu_item_use_case.dart';
import 'package:pos/domain/usecases/menu_item/update_menu_item_use_case.dart';
import 'package:pos/domain/usecases/seat/create_seat_use_case.dart';
import 'package:pos/domain/usecases/seat/delete_seat_use_case.dart';
import 'package:pos/domain/usecases/seat/update_seat_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

// --- MenuItem providers ---

@riverpod
Stream<List<MenuItem>> menuItemStream(Ref ref) =>
    ref.watch(menuItemRepositoryProvider).watchAll();

@riverpod
CreateMenuItemUseCase createMenuItemUseCase(Ref ref) =>
    CreateMenuItemUseCase(repository: ref.watch(menuItemRepositoryProvider));

@riverpod
UpdateMenuItemUseCase updateMenuItemUseCase(Ref ref) =>
    UpdateMenuItemUseCase(repository: ref.watch(menuItemRepositoryProvider));

@riverpod
DeleteMenuItemUseCase deleteMenuItemUseCase(Ref ref) =>
    DeleteMenuItemUseCase(repository: ref.watch(menuItemRepositoryProvider));

// --- Seat providers ---

@riverpod
Stream<List<Seat>> seatStream(Ref ref) =>
    ref.watch(seatRepositoryProvider).watchAll();

@riverpod
CreateSeatUseCase createSeatUseCase(Ref ref) =>
    CreateSeatUseCase(repository: ref.watch(seatRepositoryProvider));

@riverpod
UpdateSeatUseCase updateSeatUseCase(Ref ref) =>
    UpdateSeatUseCase(repository: ref.watch(seatRepositoryProvider));

@riverpod
DeleteSeatUseCase deleteSeatUseCase(Ref ref) =>
    DeleteSeatUseCase(repository: ref.watch(seatRepositoryProvider));
