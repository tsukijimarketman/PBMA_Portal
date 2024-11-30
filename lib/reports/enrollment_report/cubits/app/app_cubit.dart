
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:equatable/equatable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pbma_portal/reports/enrollment_report/urls.dart';
import 'package:pbma_portal/reports/enrollment_report/util/app_utils.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(const AppState()) {
    initialize();
  }

  void initialize() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    emit(state.copyWith(
      currentPackageInfo: packageInfo,
      availableVersionToUpdate: '',
      usingFlChartVersion: BuildConstants.usingFlChartVersion,
    ));
  }

  void onVersionClicked() {
    AppUtils().tryToLaunchUrl(
      Urls.getVersionReleaseUrl(state.usingFlChartVersion),
    );
  }
}

class BuildConstants {
  static const String usingFlChartVersion = String.fromEnvironment(
    'USING_FL_CHART_VERSION',
    defaultValue: '',
  );
}