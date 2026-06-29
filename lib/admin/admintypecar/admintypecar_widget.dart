import '/backend/admin_firestore_delete.dart';
import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'admintypecar_model.dart';
export 'admintypecar_model.dart';

/// Tourism Landmarks Management Page
///
/// At the top of the page, users are provided with two search
/// functionalities:
///
/// General Landmark Search: A search bar where users can quickly enter
/// keywords to find any landmark.
///
/// City-Specific Search: A separate search input that allows users to filter
/// landmarks based on the city.
/// Next to these search bars, there's a prominent "Add New Landmark" button.
/// This button directs users to a form where they can input details for a new
/// tourism landmark.
///
/// The main area of the page features a comprehensive table that displays all
/// added tourism landmarks. The table includes the following columns:
///
/// Landmark Name: The name of the tourism landmark.
/// Description: A brief overview or details about the landmark.
/// Available Services: Lists the services or facilities offered at the
/// landmark.
/// Country: The country where the landmark is located.
/// City: The city in which the landmark can be found.
/// Status: Indicates the current operational or review status of the
/// landmark.
/// Actions: Two action buttons are available:
/// Edit: Allows users to modify the landmark’s information.
/// Delete: Enables users to remove the landmark from the system.
/// This layout is designed to provide administrators with an intuitive and
/// efficient interface to manage tourism landmarks. The search features allow
/// for quick filtering, while the table organizes landmark data in a clear
/// and concise manner, ensuring ease of management and updates.
class AdmintypecarWidget extends StatefulWidget {
  const AdmintypecarWidget({super.key});

  static String routeName = 'Admintypecar';
  static String routePath = '/admintypecar';

  @override
  State<AdmintypecarWidget> createState() => _AdmintypecarWidgetState();
}

class _AdmintypecarWidgetState extends State<AdmintypecarWidget> {
  late AdmintypecarModel _model;
  Future<List<TypeCarRecord>>? _typeCarsFuture;
  late final void Function() _listRefreshListener;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Future<List<TypeCarRecord>> _loadTypeCars() {
    return queryListCacheFirst(
      TypeCarRecord.collection,
      TypeCarRecord.fromSnapshot,
      queryBuilder: (q) => q.orderBy('sr'),
      limit: 80,
    );
  }

  void _reloadTypeCars() {
    if (!mounted) return;
    setState(() {
      _typeCarsFuture = _loadTypeCars();
    });
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdmintypecarModel());
    _typeCarsFuture = _loadTypeCars();
    _listRefreshListener = _reloadTypeCars;
    AdminListRefresh.register(AdminListScope.typeCars, _listRefreshListener);

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    AdminListRefresh.unregister(AdminListScope.typeCars, _listRefreshListener);
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AdminLayoutWidget(
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        child: AdminPageBody(
          usePadding: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                          Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ].divide(SizedBox(width: 16.0)),
                            ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                24.0, 0.0, 24.0, 0.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 0.0, 16.0, 0.0),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          FFButtonWidget(
                                            onPressed: () async {
                                              context.pushNamed(
                                                  CarTypeAdditionWidget
                                                      .routeName);
                                            },
                                            text: FFLocalizations.of(context)
                                                .getText(
                                              'archbmcb' /* Add car type */,
                                            ),
                                            icon: Icon(
                                              Icons.directions_car,
                                              size: 15.0,
                                            ),
                                            options: FFButtonOptions(
                                              width: 150.51,
                                              height: 50.0,
                                              padding: EdgeInsets.all(8.0),
                                              iconPadding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 0.0, 0.0, 0.0),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              textStyle: FlutterFlowTheme.of(
                                                      context)
                                                  .titleSmall
                                                  .override(
                                                    fontFamily:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmallFamily,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .info,
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts:
                                                        !FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmallIsCustom,
                                                  ),
                                              elevation: 0.0,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                        ].divide(SizedBox(width: 12.0)),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 0.0, 16.0, 0.0),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 16.0, 16.0, 16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            FFLocalizations.of(context).getText(
                                              'kooml6rt' /* Types of cars */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .headlineSmall
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .headlineSmallFamily,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      !FlutterFlowTheme.of(
                                                              context)
                                                          .headlineSmallIsCustom,
                                                ),
                                          ),
                                          FutureBuilder<List<TypeCarRecord>>(
                                            future: _typeCarsFuture,
                                            builder: (context, snapshot) {
                                              if (snapshot.hasError) {
                                                return Center(
                                                  child: Text(
                                                    'تعذر تحميل أنواع السيارات',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium,
                                                  ),
                                                );
                                              }
                                              // Customize what your widget looks like when it's loading.
                                              if (!snapshot.hasData) {
                                                return Center(
                                                  child: SizedBox(
                                                    width: 55.0,
                                                    height: 55.0,
                                                    child: SpinKitThreeBounce(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      size: 55.0,
                                                    ),
                                                  ),
                                                );
                                              }
                                              List<TypeCarRecord>
                                                  listViewTypeCarRecordList =
                                                  snapshot.data!;

                                              return ListView.builder(
                                                padding: EdgeInsets.zero,
                                                primary: false,
                                                shrinkWrap: true,
                                                scrollDirection: Axis.vertical,
                                                itemCount:
                                                    listViewTypeCarRecordList
                                                        .length,
                                                itemBuilder:
                                                    (context, listViewIndex) {
                                                  final listViewTypeCarRecord =
                                                      listViewTypeCarRecordList[
                                                          listViewIndex];
                                                  return Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 0.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    12.0,
                                                                    12.0,
                                                                    12.0,
                                                                    12.0),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Expanded(
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    listViewTypeCarRecord
                                                                        .naim,
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyLarge
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).bodyLargeFamily,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).bodyLargeIsCustom,
                                                                        ),
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    height:
                                                                        4.0)),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    '${valueOrDefault<String>(
                                                                      formatNumber(
                                                                        listViewTypeCarRecord
                                                                            .sr,
                                                                        formatType:
                                                                            FormatType.decimal,
                                                                        decimalType:
                                                                            DecimalType.automatic,
                                                                        currency:
                                                                            'ريال ',
                                                                      ),
                                                                      'غير معرفة',
                                                                    )}  للساعة الواحدة',
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).bodySmallFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).error,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).bodySmallIsCustom,
                                                                        ),
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    height:
                                                                        4.0)),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    '${listViewTypeCarRecord.aglSaat.toString()} ساعات  هو الحد الأدنى للطلب',
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).bodySmallFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondaryText,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).bodySmallIsCustom,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: [
                                                                FFButtonWidget(
                                                                  onPressed:
                                                                      () async {
                                                                    final nameCtrl =
                                                                        TextEditingController(
                                                                      text: listViewTypeCarRecord
                                                                          .naim,
                                                                    );
                                                                    final rateCtrl =
                                                                        TextEditingController(
                                                                      text: listViewTypeCarRecord
                                                                          .sr
                                                                          .toString(),
                                                                    );
                                                                    final saved =
                                                                        await showDialog<
                                                                            bool>(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (ctx) {
                                                                        return AlertDialog(
                                                                          title: const Text(
                                                                              'تعديل نوع السيارة'),
                                                                          content:
                                                                              Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                              TextField(
                                                                                controller:
                                                                                    nameCtrl,
                                                                                decoration:
                                                                                    const InputDecoration(
                                                                                  labelText:
                                                                                      'الاسم',
                                                                                ),
                                                                              ),
                                                                              TextField(
                                                                                controller:
                                                                                    rateCtrl,
                                                                                keyboardType:
                                                                                    TextInputType.number,
                                                                                decoration:
                                                                                    const InputDecoration(
                                                                                  labelText:
                                                                                      'السعر للساعة',
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed: () =>
                                                                                  Navigator.pop(
                                                                                      ctx,
                                                                                      false),
                                                                              child:
                                                                                  const Text(
                                                                                      'إلغاء'),
                                                                            ),
                                                                            TextButton(
                                                                              onPressed: () =>
                                                                                  Navigator.pop(
                                                                                      ctx,
                                                                                      true),
                                                                              child:
                                                                                  const Text(
                                                                                      'حفظ'),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );
                                                                    if (saved !=
                                                                            true ||
                                                                        !context
                                                                            .mounted) {
                                                                      return;
                                                                    }
                                                                    try {
                                                                      await listViewTypeCarRecord
                                                                          .reference
                                                                          .update(
                                                                        createTypeCarRecordData(
                                                                          naim: nameCtrl
                                                                              .text
                                                                              .trim(),
                                                                          sr: int.tryParse(rateCtrl.text.trim()) ??
                                                                              listViewTypeCarRecord.sr,
                                                                        ),
                                                                      );
                                                                      if (!context
                                                                          .mounted) {
                                                                        return;
                                                                      }
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        const SnackBar(
                                                                          content:
                                                                              Text('تم حفظ التعديلات'),
                                                                        ),
                                                                      );
                                                                    } catch (e) {
                                                                      if (!context
                                                                          .mounted) {
                                                                        return;
                                                                      }
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        SnackBar(
                                                                            content:
                                                                                Text('تعذر الحفظ: $e')),
                                                                      );
                                                                    }
                                                                  },
                                                                  text: FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'i8wvudcy' /* Edit */,
                                                                  ),
                                                                  options:
                                                                      FFButtonOptions(
                                                                    width: 80.0,
                                                                    height:
                                                                        36.0,
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            8.0),
                                                                    iconPadding:
                                                                        EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            0.0),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .success,
                                                                    textStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).labelSmallFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).info,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).labelSmallIsCustom,
                                                                        ),
                                                                    elevation:
                                                                        0.0,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                  ),
                                                                ),
                                                                FFButtonWidget(
                                                                  onPressed:
                                                                      () async {
                                                                    final confirm =
                                                                        await showDialog<
                                                                            bool>(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (ctx) {
                                                                        return AlertDialog(
                                                                          title: const Text(
                                                                              'حذف نوع السيارة'),
                                                                          content: const Text(
                                                                              'هل أنت متأكد من حذف هذا النوع؟ لا يمكن التراجع.'),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed: () =>
                                                                                  Navigator.pop(
                                                                                      ctx,
                                                                                      false),
                                                                              child:
                                                                                  const Text(
                                                                                      'إلغاء'),
                                                                            ),
                                                                            TextButton(
                                                                              onPressed: () =>
                                                                                  Navigator.pop(
                                                                                      ctx,
                                                                                      true),
                                                                              child:
                                                                                  const Text(
                                                                                      'حذف'),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );
                                                                    if (confirm !=
                                                                            true ||
                                                                        !context
                                                                            .mounted) {
                                                                      return;
                                                                    }
                                                                    try {
                                                                      final docId =
                                                                          listViewTypeCarRecord
                                                                              .reference
                                                                              .id;
                                                                      await AdminFirestoreDelete
                                                                          .deleteDocument(
                                                                        listViewTypeCarRecord
                                                                            .reference,
                                                                      );
                                                                      if (!context
                                                                          .mounted) {
                                                                        return;
                                                                      }
                                                                      await AdminCrudFeedback
                                                                          .success(
                                                                        context,
                                                                        action:
                                                                            AdminCrudAction
                                                                                .delete,
                                                                        message:
                                                                            'تم حذف نوع السيارة بنجاح',
                                                                        refreshScope:
                                                                            AdminListScope
                                                                                .typeCars,
                                                                        removedDocumentId:
                                                                            docId,
                                                                        invalidateStats:
                                                                            false,
                                                                      );
                                                                    } catch (e) {
                                                                      if (!context
                                                                          .mounted) {
                                                                        return;
                                                                      }
                                                                      AdminCrudFeedback
                                                                          .error(
                                                                        context,
                                                                        'تعذر الحذف: $e',
                                                                      );
                                                                    }
                                                                  },
                                                                  text: 'حذف',
                                                                  icon: const Icon(
                                                                    Icons
                                                                        .delete_outline,
                                                                    size: 16.0,
                                                                  ),
                                                                  options:
                                                                      FFButtonOptions(
                                                                    width: 80.0,
                                                                    height:
                                                                        36.0,
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            8.0),
                                                                    iconPadding:
                                                                        EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            0.0),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    textStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).labelSmallFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).info,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).labelSmallIsCustom,
                                                                        ),
                                                                    elevation:
                                                                        0.0,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                  ),
                                                                ),
                                                                if (listViewTypeCarRecord
                                                                        .actev ==
                                                                    true)
                                                                  FFButtonWidget(
                                                                    onPressed:
                                                                        () async {
                                                                      await listViewTypeCarRecord
                                                                          .reference
                                                                          .update(
                                                                              createTypeCarRecordData(
                                                                        actev:
                                                                            false,
                                                                      ));
                                                                    },
                                                                    text: FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      'oxfcbiec' /* Parking  */,
                                                                    ),
                                                                    options:
                                                                        FFButtonOptions(
                                                                      width:
                                                                          80.0,
                                                                      height:
                                                                          36.0,
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              8.0),
                                                                      iconPadding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .error,
                                                                      textStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .override(
                                                                            fontFamily:
                                                                                FlutterFlowTheme.of(context).labelSmallFamily,
                                                                            color:
                                                                                FlutterFlowTheme.of(context).info,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            useGoogleFonts:
                                                                                !FlutterFlowTheme.of(context).labelSmallIsCustom,
                                                                          ),
                                                                      elevation:
                                                                          0.0,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                    ),
                                                                  ),
                                                                if (listViewTypeCarRecord
                                                                        .actev ==
                                                                    false)
                                                                  FFButtonWidget(
                                                                    onPressed:
                                                                        () async {
                                                                      await listViewTypeCarRecord
                                                                          .reference
                                                                          .update(
                                                                              createTypeCarRecordData(
                                                                        actev:
                                                                            true,
                                                                      ));
                                                                    },
                                                                    text: FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      '4tbswp3v' /* Activation  */,
                                                                    ),
                                                                    options:
                                                                        FFButtonOptions(
                                                                      width:
                                                                          80.0,
                                                                      height:
                                                                          36.0,
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              8.0),
                                                                      iconPadding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .tertiary,
                                                                      textStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .override(
                                                                            fontFamily:
                                                                                FlutterFlowTheme.of(context).labelSmallFamily,
                                                                            color:
                                                                                FlutterFlowTheme.of(context).info,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            useGoogleFonts:
                                                                                !FlutterFlowTheme.of(context).labelSmallIsCustom,
                                                                          ),
                                                                      elevation:
                                                                          0.0,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                    ),
                                                                  ),
                                                              ].divide(SizedBox(
                                                                  width: 8.0)),
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 16.0)),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ].divide(SizedBox(height: 24.0)),
                            ),
                          ),
                        ].divide(SizedBox(height: 24.0)),
          ),
        ),
      ),
    );
  }
}
