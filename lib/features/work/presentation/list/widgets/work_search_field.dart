import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/widgets/inputs/app_input.dart';
import '../../../../../shared/widgets/inputs/app_input_config.dart';
import '../blocs/work_bloc.dart';
import '../blocs/work_event.dart';

/// The search box above the works. Sends every change to [WorkBloc], which
/// waits for typing to pause before searching.
class WorkSearchField extends StatelessWidget {
  const WorkSearchField({super.key, this.initialQuery = ''});

  /// What the field starts with — the bloc's current query, so the text
  /// survives the view being rebuilt.
  final String initialQuery;

  @override
  Widget build(BuildContext context) {
    return AppInput(
      label: 'Pesquisar obras',
      hint: 'Pesquisar por cliente ou morada',
      labelMode: AppInputLabelMode.placeholder,
      initialValue: initialQuery,
      prefixIcon: const Icon(Icons.search),
      textInputAction: TextInputAction.search,
      onChanged: (query) =>
          context.read<WorkBloc>().add(WorkSearchChanged(query)),
    );
  }
}
