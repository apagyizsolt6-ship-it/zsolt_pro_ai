// ===========================================
// Zsolt Pro AI
// Version: v0.17.3
// File: lib/screens/match_detail_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';
import '../models/bet_builder_selection.dart';
import '../models/betslip_item.dart';
import '../services/ai_engine_v2_service.dart';
import '../services/betslip_service.dart';
import '../services/match_analysis_service.dart';
import '../services/the_odds_api_service.dart';
import '../widgets/bet_builder_selector.dart';
import '../widgets/bet_market_selector.dart';

class MatchDetailScreen extends StatefulWidget {
  final AppMatch match;

  const MatchDetailScreen({
    super.key,
    required this.match,
  });

  @override
  State<MatchDetailScreen> createState() {
    return _MatchDetailScreenState();
  }
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  static const BetSelection _defaultSingleSelection =
      BetSelection(
    market: 'AI ajánlott piac',
    selection: '1X és több mint 1,5 gól',
    icon: Icons.auto_awesome,
  );

  final BetslipService _betslipService =
      BetslipService.instance;

  final TheOddsApiService _oddsService =
      TheOddsApiService.instance;

  final MatchAnalysisService _analysisService =
      MatchAnalysisService.instance;

  BetSelection? _selectedSingleBet;

  List<BetBuilderSelection> _builderSelections =
      <BetBuilderSelection>[];

  OddsEvent? _oddsEvent;
  MatchAnalysisResult? _analysisResult;

  String? _oddsError;
  String? _analysisError;
  String? _sportKey;

  bool _isLoadingOdds = false;
  bool _isLoadingAnalysis = false;

  AppMatch get match {
    return _analysisResult?.match ??
        widget.match;
  }

  AiMatchStatistics? get _statistics {
    return _analysisResult
        ?.statisticsResult
        .statistics;
  }

  bool get _isBuilderMode {
    return _builderSelections.isNotEmpty;
  }

  int get _displayedAiScore {
    return _analysisResult?.analysis.aiScore ??
        match.aiScore;
  }

  int get _recommendedProbability {
    final double? probability =
        _analysisResult
            ?.analysis
            .recommendation
            .probability;

    if (probability == null ||
        probability <= 0) {
      return _displayedAiScore.clamp(
        0,
        100,
      );
    }

    return probability
        .round()
        .clamp(
          0,
          100,
        );
  }

  int get _selectedBetProbability {
    final BetSelection? selected =
        _selectedSingleBet;

    if (selected == null) {
      return _displayedAiScore.clamp(
        0,
        100,
      );
    }

    final String normalizedSelected =
        _normalizeText(
      selected.selection,
    );

    final String normalizedRecommendation =
        _normalizeText(
      _analysisResult
              ?.recommendation ??
          '',
    );

    if (normalizedRecommendation.isNotEmpty &&
        normalizedSelected ==
            normalizedRecommendation) {
      return _recommendedProbability;
    }

    return _displayedAiScore.clamp(
      0,
      100,
    );
  }

  @override
  void initState() {
    super.initState();

    _restoreSavedSelection();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _loadAll();
      },
    );
  }

  void _restoreSavedSelection() {
    final BetslipItem? savedItem =
        _betslipService.getItem(
      widget.match.id,
    );

    if (savedItem == null) {
      _selectedSingleBet =
          _defaultSingleSelection;
      return;
    }

    if (savedItem.isBetBuilder) {
      _builderSelections =
          List<BetBuilderSelection>.from(
        savedItem.builderSelections,
      );

      _selectedSingleBet =
          _defaultSingleSelection;
      return;
    }

    _selectedSingleBet = BetSelection(
      market: savedItem.market,
      selection: savedItem.selection,
      icon: _iconForMarket(
        savedItem.market,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meccselemzés',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Elemzés frissítése',
            onPressed:
                _isLoadingAnalysis ||
                        _isLoadingOdds
                    ? null
                    : () {
                        _loadAll(
                          forceRefresh: true,
                        );
                      },
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return _loadAll(
            forceRefresh: true,
          );
        },
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            28,
          ),
          children: [
            _MatchHeaderCard(
              match: match,
            ),
            const SizedBox(height: 16),
            _AiRecommendationCard(
              aiScore: _displayedAiScore,
              recommendation:
                  _analysisResult
                      ?.recommendation,
              recommendationMarket:
                  _analysisResult
                      ?.recommendationMarket,
              recommendationProbability:
                  _analysisResult == null
                      ? null
                      : _recommendedProbability,
              dataReliability:
                  _analysisResult
                      ?.dataReliability,
              isLoading:
                  _isLoadingAnalysis,
            ),
            const SizedBox(height: 14),
            _AnalysisStatusCard(
              match: match,
              result: _analysisResult,
              isLoading:
                  _isLoadingAnalysis,
              errorMessage:
                  _analysisError,
              onRefresh: () {
                _loadAnalysis(
                  forceRefresh: true,
                );
              },
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              icon:
                  Icons.currency_exchange,
              title: 'Valódi oddsok',
            ),
            const SizedBox(height: 10),
            _RealOddsCard(
              event: _oddsEvent,
              isLoading:
                  _isLoadingOdds,
              errorMessage:
                  _oddsError,
              sportKey:
                  _sportKey,
              homeQuote:
                  _homeWinQuote,
              drawQuote:
                  _drawQuote,
              awayQuote:
                  _awayWinQuote,
              over25Quote:
                  _over25Quote,
              under25Quote:
                  _under25Quote,
              onRefresh:
                  _loadOdds,
            ),
            const SizedBox(height: 18),
            if (!_isBuilderMode &&
                _selectedSingleBet != null)
              _ValueBetPanel(
                selection:
                    _selectedSingleBet!
                        .selection,
                aiProbability:
                    _selectedBetProbability,
                quote:
                    _selectedBetQuote,
                isLoading:
                    _isLoadingOdds ||
                        _isLoadingAnalysis,
                errorMessage:
                    _valueBetMessage,
              ),
            if (!_isBuilderMode &&
                _selectedSingleBet != null)
              const SizedBox(height: 22),
            const _SectionTitle(
              icon: Icons.auto_graph,
              title:
                  'Forma – utolsó mérkőzések',
            ),
            const SizedBox(height: 10),
            _buildFormSection(),
            const SizedBox(height: 22),
            const _SectionTitle(
              icon:
                  Icons.compare_arrows,
              title:
                  'Egymás elleni mérleg',
            ),
            const SizedBox(height: 10),
            _buildHeadToHeadSection(),
            const SizedBox(height: 22),
            const _SectionTitle(
              icon:
                  Icons.sports_soccer,
              title: 'Gólstatisztikák',
            ),
            const SizedBox(height: 10),
            _buildGoalStatisticsSection(),
            const SizedBox(height: 22),
            const _SectionTitle(
              icon:
                  Icons.query_stats,
              title:
                  'Részletes csapatstatisztikák',
            ),
            const SizedBox(height: 10),
            _buildAdvancedStatisticsSection(),
            const SizedBox(height: 28),
            _ModeInformationCard(
              singleBetSelected:
                  _selectedSingleBet !=
                      null,
              builderSelectionCount:
                  _builderSelections.length,
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              icon:
                  Icons.touch_app_outlined,
              title: 'Egyedi tipp',
            ),
            const SizedBox(height: 8),
            Text(
              'Válassz egyetlen fogadási piacot, '
              'ha nem Fogadáskészítőt szeretnél '
              'használni.',
              style: TextStyle(
                color:
                    colors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            BetMarketSelector(
              selectedBet:
                  _selectedSingleBet,
              onSelected: (
                BetSelection selection,
              ) {
                setState(() {
                  _selectedSingleBet =
                      selection;
                  _builderSelections =
                      <BetBuilderSelection>[];
                });
              },
            ),
            const SizedBox(height: 10),
            if (_selectedSingleBet != null &&
                !_isBuilderMode)
              _SelectedSingleBetCard(
                selectedBet:
                    _selectedSingleBet!,
                aiScore:
                    _selectedBetProbability,
                realOdds:
                    _selectedBetQuote
                        ?.price,
              ),
            const SizedBox(height: 26),
            const _SectionTitle(
              icon:
                  Icons.construction_outlined,
              title:
                  'Fogadáskészítő PRO',
            ),
            const SizedBox(height: 8),
            Text(
              'Jelölj ki több piacot ugyanahhoz a '
              'mérkőzéshez. A kiválasztások '
              'egyetlen Fogadáskészítőként kerülnek '
              'a szelvényre.',
              style: TextStyle(
                color:
                    colors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            BetBuilderSelector(
              selectedSelections:
                  _builderSelections,
              onChanged: (
                List<BetBuilderSelection>
                    selections,
              ) {
                setState(() {
                  _builderSelections =
                      List<
                          BetBuilderSelection>.from(
                    selections,
                  );
                });
              },
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation:
                  _betslipService,
              builder: (
                BuildContext context,
                Widget? child,
              ) {
                final BetslipItem?
                    savedItem =
                    _betslipService
                        .getItem(
                  match.id,
                );

                final bool hasSavedItem =
                    savedItem != null;

                return Column(
                  children: [
                    if (_isBuilderMode)
                      FilledButton.icon(
                        onPressed:
                            _saveBetBuilder,
                        icon: Icon(
                          hasSavedItem &&
                                  savedItem
                                      .isBetBuilder
                              ? Icons.sync
                              : Icons
                                  .add_circle_outline,
                        ),
                        label: Text(
                          hasSavedItem &&
                                  savedItem
                                      .isBetBuilder
                              ? 'Fogadáskészítő frissítése'
                              : 'Fogadáskészítő hozzáadása',
                        ),
                        style:
                            FilledButton
                                .styleFrom(
                          minimumSize:
                              const Size
                                  .fromHeight(
                            58,
                          ),
                          backgroundColor:
                              Colors.green,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                          textStyle:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed:
                            _selectedSingleBet ==
                                    null
                                ? null
                                : _saveSingleBet,
                        icon: Icon(
                          hasSavedItem &&
                                  !savedItem
                                      .isBetBuilder
                              ? Icons.sync
                              : Icons
                                  .add_circle_outline,
                        ),
                        label: Text(
                          hasSavedItem &&
                                  !savedItem
                                      .isBetBuilder
                              ? 'Egyedi tipp frissítése'
                              : 'Egyedi tipp hozzáadása',
                        ),
                        style:
                            FilledButton
                                .styleFrom(
                          minimumSize:
                              const Size
                                  .fromHeight(
                            58,
                          ),
                          backgroundColor:
                              colors.primary,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                          textStyle:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    if (hasSavedItem) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            _removeFromBetslip,
                        icon: const Icon(
                          Icons
                              .delete_outline,
                        ),
                        label: const Text(
                          'Eltávolítás a szelvényről',
                        ),
                        style:
                            OutlinedButton
                                .styleFrom(
                          minimumSize:
                              const Size
                                  .fromHeight(
                            52,
                          ),
                          foregroundColor:
                              Colors.redAccent,
                          side:
                              const BorderSide(
                            color:
                                Colors
                                    .redAccent,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                          textStyle:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    final AiMatchStatistics? statistics =
        _statistics;

    if (_isLoadingAnalysis &&
        statistics == null) {
      return const _StatisticsLoadingCard(
        message:
            'Valódi csapatforma betöltése...',
      );
    }

    if (statistics == null) {
      return _StatisticsUnavailableCard(
        message:
            _analysisError ??
                'Nem érhető el csapatforma.',
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _FormCard(
            title: match.homeTeam,
            form: _convertForm(
              statistics.homeForm,
            ),
            score: _calculateFormScore(
              statistics.homeForm,
            ),
            venueForm:
                _convertForm(
              statistics.homeVenueForm,
            ),
            venueLabel:
                'Hazai pályán',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FormCard(
            title: match.awayTeam,
            form: _convertForm(
              statistics.awayForm,
            ),
            score: _calculateFormScore(
              statistics.awayForm,
            ),
            venueForm:
                _convertForm(
              statistics.awayVenueForm,
            ),
            venueLabel:
                'Idegenben',
          ),
        ),
      ],
    );
  }

  Widget _buildHeadToHeadSection() {
    final AiMatchStatistics? statistics =
        _statistics;

    if (_isLoadingAnalysis &&
        statistics == null) {
      return const _StatisticsLoadingCard(
        message:
            'Egymás elleni adatok betöltése...',
      );
    }

    if (statistics == null) {
      return _StatisticsUnavailableCard(
        message:
            _analysisError ??
                'Nem érhető el H2H-adat.',
      );
    }

    final int total =
        statistics.h2hHomeWins +
            statistics.h2hDraws +
            statistics.h2hAwayWins;

    if (total <= 0) {
      return const _StatisticsUnavailableCard(
        message:
            'Nincs elegendő egymás elleni adat '
            'ehhez a mérkőzéshez.',
      );
    }

    return _StatisticsCard(
      rows: [
        _StatisticRowData(
          label:
              '${match.homeTeam} győzelem',
          value:
              statistics.h2hHomeWins
                  .toString(),
        ),
        _StatisticRowData(
          label: 'Döntetlen',
          value:
              statistics.h2hDraws
                  .toString(),
        ),
        _StatisticRowData(
          label:
              '${match.awayTeam} győzelem',
          value:
              statistics.h2hAwayWins
                  .toString(),
        ),
        _StatisticRowData(
          label:
              'Vizsgált H2H-meccsek',
          value:
              total.toString(),
        ),
        _StatisticRowData(
          label:
              'H2H átlagos gólszám',
          value:
              _formatDecimal(
            statistics.h2hAverageGoals,
          ),
        ),
        _StatisticRowData(
          label:
              'H2H mindkét csapat gólt szerez',
          value:
              _formatPercent(
            statistics.h2hBttsPercent,
          ),
        ),
        _StatisticRowData(
          label:
              'H2H több mint 2,5 gól',
          value:
              _formatPercent(
            statistics.h2hOver25Percent,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalStatisticsSection() {
    final AiMatchStatistics? statistics =
        _statistics;

    if (_isLoadingAnalysis &&
        statistics == null) {
      return const _StatisticsLoadingCard(
        message:
            'Gólstatisztikák betöltése...',
      );
    }

    if (statistics == null) {
      return _StatisticsUnavailableCard(
        message:
            _analysisError ??
                'Nem érhető el gólstatisztika.',
      );
    }

    return _StatisticsCard(
      rows: [
        _StatisticRowData(
          label:
              'Átlagos gólszám',
          value:
              _formatDecimal(
            statistics.leagueAverageGoals,
          ),
        ),
        _StatisticRowData(
          label:
              'Több mint 1,5 gól',
          value:
              _formatPercent(
            statistics.over15Percent,
          ),
        ),
        _StatisticRowData(
          label:
              'Több mint 2,5 gól',
          value:
              _formatPercent(
            statistics.over25Percent,
          ),
        ),
        _StatisticRowData(
          label:
              'Több mint 3,5 gól',
          value:
              _formatPercent(
            statistics.over35Percent,
          ),
        ),
        _StatisticRowData(
          label:
              'Mindkét csapat szerez gólt',
          value:
              _formatPercent(
            statistics.bttsPercent,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedStatisticsSection() {
    final AiMatchStatistics? statistics =
        _statistics;

    if (_isLoadingAnalysis &&
        statistics == null) {
      return const _StatisticsLoadingCard(
        message:
            'Részletes statisztikák betöltése...',
      );
    }

    if (statistics == null) {
      return _StatisticsUnavailableCard(
        message:
            _analysisError ??
                'Nem érhető el részletes statisztika.',
      );
    }

    return Column(
      children: [
        _StatisticsCard(
          rows: [
            _StatisticRowData(
              label:
                  '${match.homeTeam} rúgott gólátlag',
              value:
                  _formatDecimal(
                statistics
                    .homeGoalsScoredAverage,
              ),
            ),
            _StatisticRowData(
              label:
                  '${match.homeTeam} kapott gólátlag',
              value:
                  _formatDecimal(
                statistics
                    .homeGoalsConcededAverage,
              ),
            ),
            _StatisticRowData(
              label:
                  '${match.awayTeam} rúgott gólátlag',
              value:
                  _formatDecimal(
                statistics
                    .awayGoalsScoredAverage,
              ),
            ),
            _StatisticRowData(
              label:
                  '${match.awayTeam} kapott gólátlag',
              value:
                  _formatDecimal(
                statistics
                    .awayGoalsConcededAverage,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatisticsCard(
          rows: [
            _StatisticRowData(
              label:
                  '${match.homeTeam} kapott gól nélkül',
              value:
                  _formatPercent(
                statistics
                    .homeCleanSheetPercent,
              ),
            ),
            _StatisticRowData(
              label:
                  '${match.awayTeam} kapott gól nélkül',
              value:
                  _formatPercent(
                statistics
                    .awayCleanSheetPercent,
              ),
            ),
            _StatisticRowData(
              label:
                  '${match.homeTeam} nem szerzett gólt',
              value:
                  _formatPercent(
                statistics
                    .homeFailedToScorePercent,
              ),
            ),
            _StatisticRowData(
              label:
                  '${match.awayTeam} nem szerzett gólt',
              value:
                  _formatPercent(
                statistics
                    .awayFailedToScorePercent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatisticsCard(
          rows: [
            _StatisticRowData(
              label:
                  'Hazai minta nagysága',
              value:
                  '${statistics.homeSampleSize} meccs',
            ),
            _StatisticRowData(
              label:
                  'Vendég minta nagysága',
              value:
                  '${statistics.awaySampleSize} meccs',
            ),
            _StatisticRowData(
              label:
                  'Ligaerősség',
              value:
                  '${statistics.leagueStrength.round()}/100',
            ),
            _StatisticRowData(
              label:
                  'Adatminőségi bónusz',
              value:
                  _formatDecimal(
                statistics.dataQualityBonus,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _loadAll({
    bool forceRefresh = false,
  }) async {
    await Future.wait<void>(
      <Future<void>>[
        _loadAnalysis(
          forceRefresh:
              forceRefresh,
        ),
        _loadOdds(),
      ],
    );
  }

  Future<void> _loadAnalysis({
    bool forceRefresh = false,
  }) async {
    if (_isLoadingAnalysis) {
      return;
    }

    setState(() {
      _isLoadingAnalysis = true;
      _analysisError = null;
    });

    try {
      final MatchAnalysisResult result =
          await _analysisService
              .analyzeMatch(
        match:
            widget.match,
        forceRefresh:
            forceRefresh,
        allowFallback:
            true,
        formMatchCount:
            5,
        h2hMatchCount:
            8,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _analysisResult =
            result;

        if (!result.success) {
          _analysisError =
              result.errorMessage ??
                  'Az elemzés nem sikerült.';
        }

        final BetslipItem? savedItem =
            _betslipService.getItem(
          widget.match.id,
        );

        if (savedItem == null) {
          final String market =
              result
                  .recommendationMarket
                  .trim();

          final String selection =
              result
                  .recommendation
                  .trim();

          if (selection.isNotEmpty) {
            _selectedSingleBet =
                BetSelection(
              market:
                  market.isEmpty
                      ? 'AI ajánlott piac'
                      : market,
              selection:
                  selection,
              icon:
                  _iconForMarket(
                market.isEmpty
                    ? selection
                    : market,
              ),
            );
          }
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _analysisError =
            'Az AI-elemzés betöltése nem '
            'sikerült: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAnalysis =
              false;
        });
      }
    }
  }

  Future<void> _loadOdds() async {
    if (_isLoadingOdds) {
      return;
    }

    final String? resolvedSportKey =
        _resolveSportKey(
      match.league,
    );

    if (resolvedSportKey == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sportKey = null;
        _oddsEvent = null;
        _oddsError =
            'Ehhez a bajnoksághoz még nincs '
            'elérhető Odds API sportkulcs.';
      });

      return;
    }

    setState(() {
      _sportKey =
          resolvedSportKey;
      _isLoadingOdds =
          true;
      _oddsError =
          null;
    });

    try {
      final OddsEvent? result =
          await _oddsService
              .findMatchOdds(
        sportKey:
            resolvedSportKey,
        homeTeam:
            match.homeTeam,
        awayTeam:
            match.awayTeam,
        matchDate:
            _matchDateTime(),
        markets:
            const <String>[
          'h2h',
          'totals',
        ],
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _oddsEvent =
            result;

        if (result == null) {
          _oddsError =
              'A The Odds API nem talált '
              'egyező mérkőzést vagy '
              'jelenlegi oddsot.';
        }
      });
    } on OddsApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _oddsEvent =
            null;
        _oddsError =
            error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _oddsEvent =
            null;
        _oddsError =
            'Ismeretlen hiba történt: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOdds =
              false;
        });
      }
    }
  }

  DateTime _matchDateTime() {
    final List<String> timeParts =
        match.matchTime.split(
      ':',
    );

    final int hour =
        timeParts.isNotEmpty
            ? int.tryParse(
                  timeParts.first,
                ) ??
                12
            : 12;

    final int minute =
        timeParts.length > 1
            ? int.tryParse(
                  timeParts[1],
                ) ??
                0
            : 0;

    return DateTime(
      match.matchDate.year,
      match.matchDate.month,
      match.matchDate.day,
      hour,
      minute,
    );
  }

  String? _resolveSportKey(
    String league,
  ) {
    final String normalized =
        _normalizeText(
      league,
    );

    if (normalized.contains(
          'premierleague',
        ) ||
        normalized.contains(
          'angolpremier',
        )) {
      return 'soccer_epl';
    }

    if (normalized.contains(
      'championship',
    )) {
      return 'soccer_efl_champ';
    }

    if (normalized.contains(
          'laliga',
        ) ||
        normalized.contains(
          'spanyol',
        )) {
      return 'soccer_spain_la_liga';
    }

    if (normalized.contains(
          'seriea',
        ) ||
        normalized.contains(
          'olasz',
        )) {
      return 'soccer_italy_serie_a';
    }

    if (normalized.contains(
          'bundesliga',
        ) &&
        !normalized.contains(
          'austria',
        ) &&
        !normalized.contains(
          'osztrak',
        )) {
      return 'soccer_germany_bundesliga';
    }

    if (normalized.contains(
          'ligue1',
        ) ||
        normalized.contains(
          'francia',
        )) {
      return 'soccer_france_ligue_one';
    }

    if (normalized.contains(
          'eredivisie',
        ) ||
        normalized.contains(
          'holland',
        )) {
      return 'soccer_netherlands_eredivisie';
    }

    if (normalized.contains(
          'primeiraliga',
        ) ||
        normalized.contains(
          'portugal',
        )) {
      return 'soccer_portugal_primeira_liga';
    }

    if (normalized.contains(
          'championsleague',
        ) ||
        normalized.contains(
          'bajnokokligaja',
        )) {
      return 'soccer_uefa_champs_league';
    }

    if (normalized.contains(
          'europaleague',
        ) ||
        normalized.contains(
          'europaliga',
        )) {
      return 'soccer_uefa_europa_league';
    }

    if (normalized.contains(
          'conferenceleague',
        ) ||
        normalized.contains(
          'konferencialiga',
        )) {
      return 'soccer_uefa_europa_conference_league';
    }

    if (normalized.contains(
          'allsvenskan',
        ) ||
        normalized.contains(
          'swedishallsvenskan',
        ) ||
        normalized.contains(
          'svedallsvenskan',
        )) {
      return 'soccer_sweden_allsvenskan';
    }

    if (normalized.contains(
      'superettan',
    )) {
      return 'soccer_sweden_superettan';
    }

    if (normalized.contains(
          'eliteserien',
        ) ||
        normalized.contains(
          'norwayeliteserien',
        )) {
      return 'soccer_norway_eliteserien';
    }

    if (normalized.contains(
          'obos',
        ) ||
        normalized.contains(
          '1stdivisionnorway',
        )) {
      return 'soccer_norway_1st_div';
    }

    if (normalized.contains(
          'veikkausliiga',
        ) ||
        normalized.contains(
          'finlandveikkausliiga',
        )) {
      return 'soccer_finland_veikkausliiga';
    }

    if (normalized.contains(
          'denmarksuperliga',
        ) ||
        normalized.contains(
          'danishsuperliga',
        ) ||
        normalized.contains(
          'danksuperliga',
        )) {
      return 'soccer_denmark_superliga';
    }

    if (normalized.contains(
          'jupiler',
        ) ||
        normalized.contains(
          'belgiumfirstdivisiona',
        ) ||
        normalized.contains(
          'proleaguebelgium',
        )) {
      return 'soccer_belgium_first_div';
    }

    if (normalized.contains(
          'austriabundesliga',
        ) ||
        normalized.contains(
          'osztrakbundesliga',
        )) {
      return 'soccer_austria_bundesliga';
    }

    if (normalized.contains(
          'switzerlandSuperLeague'
              .toLowerCase(),
        ) ||
        normalized.contains(
          'swisssuperleague',
        ) ||
        normalized.contains(
          'svajcisuperleague',
        )) {
      return 'soccer_switzerland_superleague';
    }

    if (normalized.contains(
      'ekstraklasa',
    )) {
      return 'soccer_poland_ekstraklasa';
    }

    if (normalized.contains(
          'czechfirstleague',
        ) ||
        normalized.contains(
          'chanceliga',
        ) ||
        normalized.contains(
          'fortunaliga',
        )) {
      return 'soccer_czech_republic_first_league';
    }

    if (normalized.contains(
          'romanialiga1',
        ) ||
        normalized.contains(
          'romansuperliga',
        ) ||
        normalized.contains(
          'ligairomania',
        )) {
      return 'soccer_romania_liga1';
    }

    if (normalized.contains(
          'croatiahnl',
        ) ||
        normalized.contains(
          'supersporthnl',
        ) ||
        normalized == 'hnl') {
      return 'soccer_croatia_hnl';
    }

    if (normalized.contains(
          'slovakiasuperliga',
        ) ||
        normalized.contains(
          'nikeliga',
        )) {
      return 'soccer_slovakia_super_liga';
    }

    if (normalized.contains(
          'sloveniaprvaliga',
        ) ||
        normalized.contains(
          'prvaligatelemach',
        )) {
      return 'soccer_slovenia_prvaliga';
    }

    if (normalized.contains(
          'otpbankliga',
        ) ||
        normalized.contains(
          'hungarynbi',
        ) ||
        normalized.contains(
          'magyarno1',
        )) {
      return 'soccer_hungary_nb_i';
    }

    if (normalized.contains(
      'mls',
    )) {
      return 'soccer_usa_mls';
    }

    if (normalized.contains(
          'australia',
        ) ||
        normalized.contains(
          'aleague',
        )) {
      return 'soccer_australia_aleague';
    }

    if (normalized.contains(
          'brazil',
        ) ||
        normalized.contains(
          'brasileirao',
        )) {
      return 'soccer_brazil_campeonato';
    }

    if (normalized.contains(
      'argentina',
    )) {
      return 'soccer_argentina_primera_division';
    }

    return null;
  }

  String _normalizeText(
    String value,
  ) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ő', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ű', 'u')
        .replaceAll(
          RegExp(
            r'[^a-z0-9]',
          ),
          '',
        );
  }

  List<String> _convertForm(
    List<AiMatchResult> form,
  ) {
    return form.map(
      (AiMatchResult result) {
        switch (result) {
          case AiMatchResult.win:
            return 'G';
          case AiMatchResult.draw:
            return 'D';
          case AiMatchResult.loss:
            return 'V';
        }
      },
    ).toList(
      growable: false,
    );
  }

  int _calculateFormScore(
    List<AiMatchResult> form,
  ) {
    if (form.isEmpty) {
      return 0;
    }

    int points = 0;

    for (final AiMatchResult result
        in form) {
      switch (result) {
        case AiMatchResult.win:
          points += 3;
          break;
        case AiMatchResult.draw:
          points += 1;
          break;
        case AiMatchResult.loss:
          break;
      }
    }

    final int maximumPoints =
        form.length * 3;

    if (maximumPoints <= 0) {
      return 0;
    }

    return (points /
            maximumPoints *
            100)
        .round()
        .clamp(
          0,
          100,
        );
  }

  String _formatPercent(
    double value,
  ) {
    return '${value.clamp(0, 100).round()}%';
  }

  String _formatDecimal(
    double value,
  ) {
    return value
        .toStringAsFixed(
          2,
        )
        .replaceAll(
          '.',
          ',',
        );
  }

  _OddsQuote? get _homeWinQuote {
    final OddsEvent? event =
        _oddsEvent;

    if (event == null) {
      return null;
    }

    return _findOutcomeQuote(
      event: event,
      marketKey: 'h2h',
      outcomeName:
          event.homeTeam,
    );
  }

  _OddsQuote? get _drawQuote {
    final OddsEvent? event =
        _oddsEvent;

    if (event == null) {
      return null;
    }

    return _findOutcomeQuote(
      event: event,
      marketKey: 'h2h',
      outcomeName: 'Draw',
    );
  }

  _OddsQuote? get _awayWinQuote {
    final OddsEvent? event =
        _oddsEvent;

    if (event == null) {
      return null;
    }

    return _findOutcomeQuote(
      event: event,
      marketKey: 'h2h',
      outcomeName:
          event.awayTeam,
    );
  }

  _OddsQuote? get _over25Quote {
    final OddsEvent? event =
        _oddsEvent;

    if (event == null) {
      return null;
    }

    return _findTotalQuote(
      event: event,
      side: 'Over',
      point: 2.5,
    );
  }

  _OddsQuote? get _under25Quote {
    final OddsEvent? event =
        _oddsEvent;

    if (event == null) {
      return null;
    }

    return _findTotalQuote(
      event: event,
      side: 'Under',
      point: 2.5,
    );
  }

  _OddsQuote? get _selectedBetQuote {
    final BetSelection? selected =
        _selectedSingleBet;

    final OddsEvent? event =
        _oddsEvent;

    if (selected == null ||
        event == null) {
      return null;
    }

    final String selection =
        _normalizeText(
      selected.selection,
    );

    if (selection.contains(
      'hazaigyozelem',
    )) {
      return _homeWinQuote;
    }

    if (selection ==
            'dontetlen' ||
        selection == 'x') {
      return _drawQuote;
    }

    if (selection.contains(
      'vendeggyozelem',
    )) {
      return _awayWinQuote;
    }

    final bool isOver =
        selection.contains(
      'tobbmint',
    );

    final bool isUnder =
        selection.contains(
      'kevesebbmint',
    );

    final double? point =
        _extractGoalPoint(
      selected.selection,
    );

    if ((isOver || isUnder) &&
        point != null) {
      return _findTotalQuote(
        event: event,
        side:
            isOver
                ? 'Over'
                : 'Under',
        point: point,
      );
    }

    return null;
  }

  String? get _valueBetMessage {
    if (_isLoadingOdds ||
        _isLoadingAnalysis) {
      return null;
    }

    if (_oddsError != null) {
      return _oddsError;
    }

    if (_selectedBetQuote == null) {
      return 'A kiválasztott piac oddsát a '
          'jelenlegi h2h/totals lekérés még '
          'nem támogatja.';
    }

    return null;
  }

  double? _extractGoalPoint(
    String selection,
  ) {
    final RegExp expression =
        RegExp(
      r'(\d+)[,.](\d+)',
    );

    final RegExpMatch? result =
        expression.firstMatch(
      selection,
    );

    if (result == null) {
      return null;
    }

    final String value =
        '${result.group(1)}.'
        '${result.group(2)}';

    return double.tryParse(
      value,
    );
  }

  _OddsQuote? _findOutcomeQuote({
    required OddsEvent event,
    required String marketKey,
    required String outcomeName,
  }) {
    final String normalizedOutcome =
        _normalizeText(
      outcomeName,
    );

    _OddsQuote? bestQuote;

    for (final OddsBookmaker bookmaker
        in event.bookmakers) {
      final OddsMarket? market =
          bookmaker.marketByKey(
        marketKey,
      );

      if (market == null) {
        continue;
      }

      for (final OddsOutcome outcome
          in market.outcomes) {
        if (_normalizeText(
              outcome.name,
            ) !=
            normalizedOutcome) {
          continue;
        }

        if (outcome.price <= 0) {
          continue;
        }

        if (bestQuote == null ||
            outcome.price >
                bestQuote.price) {
          bestQuote = _OddsQuote(
            price:
                outcome.price,
            bookmaker:
                bookmaker.title,
          );
        }
      }
    }

    return bestQuote;
  }

  _OddsQuote? _findTotalQuote({
    required OddsEvent event,
    required String side,
    required double point,
  }) {
    _OddsQuote? bestQuote;

    for (final OddsBookmaker bookmaker
        in event.bookmakers) {
      final OddsMarket? market =
          bookmaker.marketByKey(
        'totals',
      );

      if (market == null) {
        continue;
      }

      for (final OddsOutcome outcome
          in market.outcomes) {
        final bool sameSide =
            outcome.name
                    .toLowerCase() ==
                side.toLowerCase();

        final bool samePoint =
            outcome.point != null &&
                (outcome.point! -
                            point)
                        .abs() <
                    0.001;

        if (!sameSide ||
            !samePoint ||
            outcome.price <= 0) {
          continue;
        }

        if (bestQuote == null ||
            outcome.price >
                bestQuote.price) {
          bestQuote = _OddsQuote(
            price:
                outcome.price,
            bookmaker:
                bookmaker.title,
          );
        }
      }
    }

    return bestQuote;
  }

  void _saveSingleBet() {
    final BetSelection? selectedBet =
        _selectedSingleBet;

    if (selectedBet == null) {
      return;
    }

    final BetslipItem? existingItem =
        _betslipService.getItem(
      match.id,
    );

    final bool alreadySaved =
        existingItem != null;

    final double odds =
        _selectedBetQuote
                ?.price ??
            0.0;

    if (alreadySaved) {
      _betslipService.updateItem(
        matchId:
            match.id,
        market:
            selectedBet.market,
        selection:
            selectedBet.selection,
        builderSelections:
            const <
                BetBuilderSelection>[],
        odds:
            odds,
      );
    } else {
      _betslipService.addMatch(
        match,
        market:
            selectedBet.market,
        selection:
            selectedBet.selection,
        odds:
            odds,
      );
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            alreadySaved
                ? '${match.homeTeam} – '
                    '${match.awayTeam} '
                    'tippje frissítve.'
                : '${match.homeTeam} – '
                    '${match.awayTeam} '
                    'hozzáadva.',
          ),
        ),
      );
  }

  void _saveBetBuilder() {
    if (_builderSelections.isEmpty) {
      return;
    }

    final List<BetBuilderSelection>
        selectionsWithOdds =
        _builderSelections.map(
      (
        BetBuilderSelection selection,
      ) {
        final double odds =
            _findBuilderSelectionOdds(
                  selection,
                ) ??
                0.0;

        return selection.copyWith(
          odds: odds,
        );
      },
    ).toList(
      growable: false,
    );

    final bool alreadySaved =
        _betslipService.contains(
      match.id,
    );

    final bool saved =
        _betslipService
            .saveBetBuilder(
      match,
      selections:
          selectionsWithOdds,
    );

    if (!saved) {
      return;
    }

    setState(() {
      _builderSelections =
          List<
              BetBuilderSelection>.from(
        selectionsWithOdds,
      );
    });

    final int averageAi =
        _calculateBuilderAiScore(
      selectionsWithOdds,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            alreadySaved
                ? 'Fogadáskészítő frissítve: '
                    '${selectionsWithOdds.length} '
                    'tipp, AI $averageAi%.'
                : 'Fogadáskészítő hozzáadva: '
                    '${selectionsWithOdds.length} '
                    'tipp, AI $averageAi%.',
          ),
        ),
      );
  }

  double? _findBuilderSelectionOdds(
    BetBuilderSelection selection,
  ) {
    final OddsEvent? event =
        _oddsEvent;

    if (event == null) {
      return null;
    }

    final String normalized =
        _normalizeText(
      selection.selection,
    );

    final double? point =
        _extractGoalPoint(
      selection.selection,
    );

    if (point != null &&
        normalized.contains(
          'tobbmint',
        )) {
      return _findTotalQuote(
        event: event,
        side: 'Over',
        point: point,
      )?.price;
    }

    if (point != null &&
        normalized.contains(
          'kevesebbmint',
        )) {
      return _findTotalQuote(
        event: event,
        side: 'Under',
        point: point,
      )?.price;
    }

    return null;
  }

  void _removeFromBetslip() {
    final bool removed =
        _betslipService.removeMatch(
      match.id,
    );

    if (!removed) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${match.homeTeam} – '
            '${match.awayTeam} '
            'eltávolítva a szelvényről.',
          ),
        ),
      );
  }

  int _calculateBuilderAiScore(
    List<BetBuilderSelection> selections,
  ) {
    if (selections.isEmpty) {
      return 0;
    }

    final int total =
        selections.fold<int>(
      0,
      (
        int sum,
        BetBuilderSelection selection,
      ) {
        return sum +
            selection.aiScore;
      },
    );

    return (total /
            selections.length)
        .round();
  }

  IconData _iconForMarket(
    String market,
  ) {
    final String value =
        market.toLowerCase();

    if (value.contains(
      'szöglet',
    )) {
      return Icons.flag_outlined;
    }

    if (value.contains(
      'lap',
    )) {
      return Icons.style_outlined;
    }

    if (value.contains(
      'les',
    )) {
      return Icons.block_outlined;
    }

    if (value.contains(
      'szabálytalanság',
    )) {
      return Icons
          .warning_amber_rounded;
    }

    if (value.contains(
      'gól',
    )) {
      return Icons.sports_soccer;
    }

    if (value.contains(
      'mindkét',
    )) {
      return Icons.groups_outlined;
    }

    if (value.contains(
      'dupla',
    )) {
      return Icons.compare_arrows;
    }

    if (value.contains(
      'győztese',
    )) {
      return Icons
          .emoji_events_outlined;
    }

    if (value.contains(
      'ai',
    )) {
      return Icons.psychology;
    }

    return Icons.sports_soccer;
  }
}

class _OddsQuote {
  final double price;
  final String bookmaker;

  const _OddsQuote({
    required this.price,
    required this.bookmaker,
  });
}

class _AnalysisStatusCard
    extends StatelessWidget {
  final AppMatch match;
  final MatchAnalysisResult? result;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;

  const _AnalysisStatusCard({
    required this.match,
    required this.result,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    if (isLoading &&
        result == null) {
      return Card(
        child: Padding(
          padding:
              const EdgeInsets.all(
            18,
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 26,
                height: 26,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      'Valódi statisztikák betöltése',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${match.dataSourceLabel} '
                      'adatainak feldolgozása...',
                      style: TextStyle(
                        color: colors
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (result == null) {
      return Card(
        child: Padding(
          padding:
              const EdgeInsets.all(
            18,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons
                        .error_outline,
                    color:
                        Colors.orangeAccent,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Az elemzés nem érhető el',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage ??
                    'Ismeretlen elemzési hiba.',
                style: TextStyle(
                  color:
                      colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    onRefresh,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Újrapróbálás',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool realStatistics =
        result!.hasRealStatistics;

    final Color statusColor =
        realStatistics
            ? Colors.greenAccent
            : Colors.orangeAccent;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  realStatistics
                      ? Icons
                          .verified_outlined
                      : Icons
                          .info_outline,
                  color:
                      statusColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    realStatistics
                        ? 'Valódi statisztikai elemzés'
                        : 'Becsült statisztikai elemzés',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _StatusInformationRow(
              label:
                  'Adatforrás',
              value:
                  result!.dataSourceLabel,
            ),
            const SizedBox(height: 8),
            _StatusInformationRow(
              label:
                  'Adatminőség',
              value:
                  result!.qualityLabel,
            ),
            const SizedBox(height: 8),
            _StatusInformationRow(
              label:
                  'Megbízhatóság',
              value:
                  '${result!.dataReliability}%',
            ),
            const SizedBox(height: 8),
            _StatusInformationRow(
              label:
                  'Vizsgált minta',
              value:
                  '${result!.statisticsResult.sampleSize} meccs',
            ),
            if (result!.hasWarning) ...[
              const SizedBox(height: 14),
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.orange
                          .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.orangeAccent
                            .withValues(
                      alpha: 0.45,
                    ),
                  ),
                ),
                child: Text(
                  result!
                      .warningMessage!,
                  style:
                      const TextStyle(
                    color:
                        Colors.orangeAccent,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusInformationRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _StatusInformationRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.end,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _RealOddsCard
    extends StatelessWidget {
  final OddsEvent? event;
  final bool isLoading;
  final String? errorMessage;
  final String? sportKey;
  final _OddsQuote? homeQuote;
  final _OddsQuote? drawQuote;
  final _OddsQuote? awayQuote;
  final _OddsQuote? over25Quote;
  final _OddsQuote? under25Quote;
  final Future<void> Function() onRefresh;

  const _RealOddsCard({
    required this.event,
    required this.isLoading,
    required this.errorMessage,
    required this.sportKey,
    required this.homeQuote,
    required this.drawQuote,
    required this.awayQuote,
    required this.over25Quote,
    required this.under25Quote,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color:
                        colors
                            .primaryContainer,
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    Icons
                        .currency_exchange,
                    color:
                        colors
                            .onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'The Odds API',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip:
                      'Oddsok frissítése',
                  onPressed:
                      isLoading
                          ? null
                          : onRefresh,
                  icon:
                      const Icon(
                    Icons.refresh,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (isLoading)
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(
                        height: 13,
                      ),
                      Text(
                        'Valódi oddsok betöltése...',
                      ),
                    ],
                  ),
                ),
              )
            else if (event != null) ...[
              Text(
                '${event!.homeTeam} – '
                '${event!.awayTeam}',
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              if (sportKey != null) ...[
                const SizedBox(
                  height: 4,
                ),
                Text(
                  sportKey!,
                  style: TextStyle(
                    color:
                        colors
                            .onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                '1X2 – legjobb elérhető odds',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _OddsBox(
                      label:
                          'Hazai',
                      quote:
                          homeQuote,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OddsBox(
                      label:
                          'Döntetlen',
                      quote:
                          drawQuote,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OddsBox(
                      label:
                          'Vendég',
                      quote:
                          awayQuote,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Összes gól 2,5',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _OddsBox(
                      label:
                          'Over 2,5',
                      quote:
                          over25Quote,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OddsBox(
                      label:
                          'Under 2,5',
                      quote:
                          under25Quote,
                    ),
                  ),
                ],
              ),
            ] else
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.orange
                          .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.orangeAccent,
                  ),
                ),
                child: Text(
                  errorMessage ??
                      'Nincs elérhető odds adat.',
                  style:
                      const TextStyle(
                    color:
                        Colors.orangeAccent,
                  ),
                ),
              ),
            if (!isLoading &&
                event == null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    onRefresh,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Újrapróbálás',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OddsBox extends StatelessWidget {
  final String label;
  final _OddsQuote? quote;

  const _OddsBox({
    required this.label,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color:
            colors
                .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(
          13,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  colors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            quote == null
                ? '—'
                : quote!.price
                    .toStringAsFixed(
                      2,
                    ),
            style: TextStyle(
              color: quote == null
                  ? colors
                      .onSurfaceVariant
                  : colors.primary,
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quote?.bookmaker ??
                'Nincs adat',
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  colors.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueBetPanel
    extends StatelessWidget {
  final String selection;
  final int aiProbability;
  final _OddsQuote? quote;
  final bool isLoading;
  final String? errorMessage;

  const _ValueBetPanel({
    required this.selection,
    required this.aiProbability,
    required this.quote,
    required this.isLoading,
    required this.errorMessage,
  });

  double? get _fairOdds {
    if (aiProbability <= 0) {
      return null;
    }

    return 100 /
        aiProbability;
  }

  double? get _valuePercent {
    final double? fair =
        _fairOdds;

    if (fair == null ||
        quote == null) {
      return null;
    }

    return ((quote!.price /
                    fair) -
                1) *
            100;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final double? value =
        _valuePercent;

    final bool isValue =
        value != null &&
            value > 0;

    final Color statusColor =
        value == null
            ? colors
                .onSurfaceVariant
            : isValue
                ? Colors.greenAccent
                : Colors.redAccent;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons
                      .local_fire_department,
                  color:
                      Colors.orangeAccent,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'AI Value Bet elemzés',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 21,
                    height: 21,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              selection,
              style: const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'AI valószínűség: '
              '$aiProbability%',
              style: TextStyle(
                color:
                    colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 15),
            _ValueLine(
              label:
                  'Valódi odds',
              value:
                  quote == null
                      ? '—'
                      : quote!.price
                          .toStringAsFixed(
                            2,
                          ),
            ),
            const SizedBox(height: 10),
            _ValueLine(
              label:
                  'AI Fair Odds',
              value:
                  _fairOdds == null
                      ? '—'
                      : _fairOdds!
                          .toStringAsFixed(
                            2,
                          ),
            ),
            const SizedBox(height: 10),
            _ValueLine(
              label:
                  'Értékelőny',
              value:
                  value == null
                      ? '—'
                      : '${value > 0 ? '+' : ''}'
                          '${value.toStringAsFixed(1)}%',
              valueColor:
                  statusColor,
            ),
            if (quote != null) ...[
              const SizedBox(height: 10),
              _ValueLine(
                label:
                    'Legjobb iroda',
                value:
                    quote!.bookmaker,
              ),
            ],
            const SizedBox(height: 15),
            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                13,
              ),
              decoration:
                  BoxDecoration(
                color:
                    statusColor
                        .withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
                border:
                    Border.all(
                  color:
                      statusColor
                          .withValues(
                    alpha: 0.35,
                  ),
                ),
              ),
              child: Text(
                value == null
                    ? errorMessage ??
                        'Valódi oddsra vár.'
                    : isValue
                        ? '🔥 VALUE BET – az odds magasabb '
                            'az AI fair értékénél.'
                        : 'NEM VALUE BET – az odds nem ad '
                            'pozitív értékelőnyt.',
                style: TextStyle(
                  color:
                      statusColor,
                  fontWeight:
                      FontWeight.bold,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueLine
    extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ValueLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            color:
                valueColor ??
                    colors.primary,
            fontSize: 16,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ModeInformationCard
    extends StatelessWidget {
  final bool singleBetSelected;
  final int builderSelectionCount;

  const _ModeInformationCard({
    required this.singleBetSelected,
    required this.builderSelectionCount,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final bool builderMode =
        builderSelectionCount > 0;

    return Card(
      color: builderMode
          ? Colors.green.withValues(
              alpha: 0.12,
            )
          : colors.primaryContainer
              .withValues(
              alpha: 0.28,
            ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Row(
          children: [
            Icon(
              builderMode
                  ? Icons
                      .construction_outlined
                  : Icons
                      .touch_app_outlined,
              color: builderMode
                  ? Colors.greenAccent
                  : colors.primary,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                builderMode
                    ? 'Fogadáskészítő mód – '
                        '$builderSelectionCount '
                        'kiválasztás'
                    : singleBetSelected
                        ? 'Egyedi tipp mód'
                        : 'Válassz egy tippet',
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedSingleBetCard
    extends StatelessWidget {
  final BetSelection selectedBet;
  final int aiScore;
  final double? realOdds;

  const _SelectedSingleBetCard({
    required this.selectedBet,
    required this.aiScore,
    required this.realOdds,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Card(
      color: colors.primaryContainer
          .withValues(
        alpha: 0.35,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Row(
          children: [
            Icon(
              selectedBet.icon,
              color:
                  colors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    selectedBet.market,
                    style: TextStyle(
                      color:
                          colors.primary,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    selectedBet
                        .selection,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  '$aiScore%',
                  style: TextStyle(
                    color:
                        colors.primary,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  realOdds == null
                      ? 'Odds —'
                      : 'Odds '
                          '${realOdds!.toStringAsFixed(2)}',
                  style: TextStyle(
                    color:
                        colors
                            .onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchHeaderCard
    extends StatelessWidget {
  final AppMatch match;

  const _MatchHeaderCard({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: Column(
          children: [
            Text(
              match.league.isEmpty
                  ? 'Ismeretlen bajnokság'
                  : match.league,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    colors.primary,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _TeamColumn(
                    icon:
                        Icons.shield,
                    teamName:
                        match.homeTeam,
                    logoUrl:
                        match
                            .homeTeamLogoUrl,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      match.matchTime
                              .isEmpty
                          ? '--:--'
                          : match
                              .matchTime,
                      style:
                          const TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                    const Text(
                      'VS',
                    ),
                  ],
                ),
                Expanded(
                  child: _TeamColumn(
                    icon:
                        Icons
                            .shield_outlined,
                    teamName:
                        match.awayTeam,
                    logoUrl:
                        match
                            .awayTeamLogoUrl,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final IconData icon;
  final String teamName;
  final String logoUrl;

  const _TeamColumn({
    required this.icon,
    required this.teamName,
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          padding:
              const EdgeInsets.all(
            6,
          ),
          decoration:
              BoxDecoration(
            color:
                colors
                    .surfaceContainerHighest,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          child: logoUrl
                  .trim()
                  .isEmpty
              ? Icon(
                  icon,
                  size: 42,
                  color:
                      colors.primary,
                )
              : Image.network(
                  logoUrl,
                  fit:
                      BoxFit.contain,
                  errorBuilder: (
                    BuildContext context,
                    Object error,
                    StackTrace?
                        stackTrace,
                  ) {
                    return Icon(
                      icon,
                      size: 42,
                      color:
                          colors.primary,
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),
        Text(
          teamName,
          textAlign:
              TextAlign.center,
          maxLines: 2,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _AiRecommendationCard
    extends StatelessWidget {
  final int aiScore;
  final String? recommendation;
  final String? recommendationMarket;
  final int? recommendationProbability;
  final int? dataReliability;
  final bool isLoading;

  const _AiRecommendationCard({
    required this.aiScore,
    required this.recommendation,
    required this.recommendationMarket,
    required this.recommendationProbability,
    required this.dataReliability,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          18,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology,
                  size: 38,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Zsolt Pro AI elemzés',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  )
                else
                  Text(
                    '$aiScore%',
                    style: TextStyle(
                      color:
                          colors.primary,
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (recommendation != null &&
                recommendation!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 10),
              Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  recommendationMarket
                              ?.trim()
                              .isNotEmpty ==
                          true
                      ? recommendationMarket!
                      : 'AI ajánlott piac',
                  style: TextStyle(
                    color:
                        colors.primary,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  recommendation!,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              if (recommendationProbability !=
                  null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Tipp valószínűsége: '
                    '$recommendationProbability%',
                    style: TextStyle(
                      color:
                          colors
                              .onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              if (dataReliability !=
                  null) ...[
                const SizedBox(height: 5),
                Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Adatmegbízhatóság: '
                    '$dataReliability%',
                    style: TextStyle(
                      color:
                          colors
                              .onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle
    extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color:
              Theme.of(context)
                  .colorScheme
                  .primary,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final List<String> form;
  final int score;
  final List<String> venueForm;
  final String venueLabel;

  const _FormCard({
    required this.title,
    required this.form,
    required this.score,
    required this.venueForm,
    required this.venueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          14,
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign:
                  TextAlign.center,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _FormCircles(
              form: form,
            ),
            const SizedBox(height: 12),
            Text(
              '$score%',
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              venueLabel,
              style: TextStyle(
                color:
                    Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            _FormCircles(
              form:
                  venueForm,
              compact:
                  true,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCircles
    extends StatelessWidget {
  final List<String> form;
  final bool compact;

  const _FormCircles({
    required this.form,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (form.isEmpty) {
      return Text(
        'Nincs adat',
        style: TextStyle(
          color:
              Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
          fontSize:
              compact
                  ? 11
                  : 12,
        ),
      );
    }

    return Wrap(
      alignment:
          WrapAlignment.center,
      spacing:
          compact
              ? 3
              : 5,
      runSpacing:
          4,
      children: form.map(
        (String result) {
          Color backgroundColor;

          switch (result) {
            case 'G':
              backgroundColor =
                  Colors.green;
              break;
            case 'D':
              backgroundColor =
                  Colors.orange;
              break;
            case 'V':
              backgroundColor =
                  Colors.redAccent;
              break;
            default:
              backgroundColor =
                  Colors.grey;
          }

          return CircleAvatar(
            radius:
                compact
                    ? 10
                    : 13,
            backgroundColor:
                backgroundColor
                    .withValues(
              alpha: 0.30,
            ),
            child: Text(
              result,
              style: TextStyle(
                color:
                    backgroundColor,
                fontSize:
                    compact
                        ? 9
                        : 11,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          );
        },
      ).toList(),
    );
  }
}

class _StatisticsLoadingCard
    extends StatelessWidget {
  final String message;

  const _StatisticsLoadingCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          22,
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.7,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsUnavailableCard
    extends StatelessWidget {
  final String message;

  const _StatisticsUnavailableCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          18,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              color:
                  Colors.orangeAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color:
                      colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsCard
    extends StatelessWidget {
  final List<_StatisticRowData> rows;

  const _StatisticsCard({
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Column(
          children: rows.map(
            (
              _StatisticRowData row,
            ) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      row.value,
                      textAlign:
                          TextAlign.end,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}

class _StatisticRowData {
  final String label;
  final String value;

  const _StatisticRowData({
    required this.label,
    required this.value,
  });
}
