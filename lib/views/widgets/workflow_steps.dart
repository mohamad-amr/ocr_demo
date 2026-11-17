import 'package:flutter/material.dart';
import '../../cubit/ocr_cubit.dart';

class WorkflowSteps extends StatelessWidget {
  const WorkflowSteps({super.key, required this.status});
  final OcrStatus status;
  @override
  Widget build(BuildContext context) {
    final active = switch (status) {
      OcrStatus.processing => 1,
      OcrStatus.success => 2,
      _ => 0,
    };
    return Row(
      key: const ValueKey('workflow-steps'),
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Semantics(
              label:
                  '${['Upload', 'Review', 'Marked PDF'][i]}, ${i < active
                      ? 'complete'
                      : i == active
                      ? 'current step'
                      : 'upcoming'}',
              child: Container(
                padding: const EdgeInsets.only(top: 17, bottom: 15),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 2,
                      color: i <= active
                          ? const Color(0xFFAE97DD)
                          : const Color(0xFF29272F),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 17,
                      child: i < active
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Color(0xFFAE97DD),
                            )
                          : Text(
                              '0${i + 1}',
                              style: TextStyle(
                                fontFamily: 'GeistMono',
                                fontSize: 9,
                                color: i == active
                                    ? const Color(0xFFBCA6E6)
                                    : Colors.white30,
                              ),
                            ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        ['Upload', 'Review', 'Marked PDF'][i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: i == active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: i == active ? Colors.white : Colors.white38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
