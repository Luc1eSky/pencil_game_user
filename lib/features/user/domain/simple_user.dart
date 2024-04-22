import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_user.dart';

part 'simple_user.freezed.dart';
part 'simple_user.g.dart';

@freezed
class SimpleUser with _$SimpleUser {
  const SimpleUser._();
  const factory SimpleUser({
    required String firstName,
    required String uid,
    required String colorCode,
  }) = _SimpleUser;

  factory SimpleUser.fromJson(Map<String, dynamic> json) => _$SimpleUserFromJson(json);

  factory SimpleUser.fromAppUser(AppUser appUser) => SimpleUser(
        firstName: appUser.firstName,
        uid: appUser.uid,
        colorCode: appUser.colorCode,
      );
}
