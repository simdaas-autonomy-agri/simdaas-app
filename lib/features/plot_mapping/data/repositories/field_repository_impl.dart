import '../../domain/entities/plot.dart';
import '../datasources/field_remote_data_source.dart';
import '../models/plot_model.dart';

abstract class PlotRepository {
  Future<void> addPlot(PlotModel plot);
  Future<List<PlotEntity>> getPlots(String userId);
}

class PlotRepositoryImpl implements PlotRepository {
  final PlotRemoteDataSource remote;
  PlotRepositoryImpl(this.remote);

  @override
  Future<void> addPlot(PlotModel plot) async {
    return remote.addPlot(plot);
  }

  @override
  Future<List<PlotEntity>> getPlots(String userId) async {
    final models = await remote.getPlots(userId);
    return models;
  }
}
