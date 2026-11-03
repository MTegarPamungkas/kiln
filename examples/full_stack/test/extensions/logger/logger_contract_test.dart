import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/extensions/logger/log_sink.dart';
import 'package:full_stack/extensions/logger/memory_log_sink.dart';
import 'package:full_stack/extensions/logger/sink_pipeline.dart';

void main() {
  loggerContract(
    description: 'PipelineLogger',
    create: () {
      final memory = MemoryLogSink(capacity: 16);
      final logger = PipelineLogger(
        pipeline: SinkPipeline(<LogSink>[memory]),
      );
      return _LoggerHarness(logger, memory);
    },
  );
}

final class _LoggerHarness implements LoggerContractHarness {
  _LoggerHarness(this.logger, this.memory);

  @override
  final AppLogger logger;
  final MemoryLogSink memory;

  @override
  List<LogRecord> get records => memory.records;
}
