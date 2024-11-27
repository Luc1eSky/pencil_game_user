import 'package:freezed_annotation/freezed_annotation.dart';

part 'survey.freezed.dart';
part 'survey.g.dart';

/// Enum for treatment
@JsonEnum(alwaysCreate: true)
enum Gender { male, female, other, preferNotToAnswer }

@JsonEnum(alwaysCreate: true)
enum AgeGroup {
  @JsonValue('under 18')
  under18,

  @JsonValue('18-20')
  eighteenToTwenty,

  @JsonValue('21-23')
  twentyOneToTwentyThree,

  @JsonValue('24-26')
  twentyFourToTwentySix,

  @JsonValue('over 27')
  over26,
}

@freezed
class Survey with _$Survey {
  const factory Survey({
    required Gender gender,
    //required AgeGroup ageGroup,
  }) = _Survey;

  factory Survey.fromJson(Map<String, dynamic> json) => _$SurveyFromJson(json);
}
