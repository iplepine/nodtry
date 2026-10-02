// Test double: a FirebaseFirestore that forwards to a FakeFirebaseFirestore
// and records every query the app runs, so tests can assert the exact query
// shapes and check them against firestore.rules.next.
//
// firestore.rules.next lets a query through only when its own constraints
// prove that every result is readable ("rules are not filters"). For list
// reads that means, per disjunct of the query:
//   plans / actions  `userId == me` or `managerId == me`
//   relations        `executorId == me` or `managerId == me`
//   cheers           `fromUserId == me` or `toUserId == me`
//   users            never (get by uid only)
//   config           always
// The emulator suites in rules-tests/test-next prove the same shapes against
// the real rules; this keeps the app's side of that contract under test.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// One condition of a query: `field op value`.
class QueryCond {
  const QueryCond(this.field, this.op, this.value);

  final String field;
  final String op;
  final Object? value;

  @override
  String toString() => '$field $op ${_format(value)}';
}

/// A query the app ran, with its filters in disjunctive normal form (an OR
/// of ANDs; no filter at all is one empty AND).
class RecordedQuery {
  const RecordedQuery({
    required this.collection,
    required this.disjuncts,
    required this.orderBy,
    required this.limit,
  });

  final String collection;
  final List<List<QueryCond>> disjuncts;
  final List<String> orderBy;
  final int? limit;

  /// e.g. `actions where planId == p1 && managerId == me orderBy date desc`.
  String get shape {
    final buffer = StringBuffer(collection);
    final filters = disjuncts
        .where((conds) => conds.isNotEmpty)
        .map((conds) => conds.join(' && '))
        .toList();
    if (filters.isNotEmpty) buffer.write(' where ${filters.join(' || ')}');
    if (orderBy.isNotEmpty) buffer.write(' orderBy ${orderBy.join(', ')}');
    if (limit != null) buffer.write(' limit $limit');
    return buffer.toString();
  }

  /// Why firestore.rules.next would deny this query for [me], or null.
  String? rulesNextViolation(String me) {
    if (collection == 'config') return null;
    if (collection == 'users') return 'users can not be listed';
    final fields = _participantFields[collection];
    if (fields == null) return 'no list rule for $collection';
    for (final conds in disjuncts) {
      final proven = conds.any(
        (c) => c.op == '==' && fields.contains(c.field) && c.value == me,
      );
      if (!proven) {
        return 'a disjunct lacks ${fields.join(' / ')} == $me';
      }
    }
    return null;
  }

  @override
  String toString() => shape;
}

const _participantFields = {
  'plans': ['userId', 'managerId'],
  'actions': ['userId', 'managerId'],
  'relations': ['executorId', 'managerId'],
  'cheers': ['fromUserId', 'toUserId'],
};

String _format(Object? value) {
  if (value is Timestamp || value is DateTime) return '<time>';
  if (value is Iterable) return '[${value.map(_format).join(', ')}]';
  return '$value';
}

String _fieldName(Object? field) {
  if (field is String) return field;
  if (field is FieldPath) return field.components.join('.');
  return '$field';
}

List<List<QueryCond>> _and(
  List<List<QueryCond>> left,
  List<List<QueryCond>> right,
) => [
  for (final a in left)
    for (final b in right) [...a, ...b],
];

/// [filter] (a `Filter`'s JSON) in disjunctive normal form.
List<List<QueryCond>> _dnf(Map<Object?, Object?> filter) {
  final op = '${filter['op']}';
  final queries = filter['queries'];
  if (queries is List) {
    final parts = [for (final q in queries) _dnf(q as Map<Object?, Object?>)];
    if (op.toUpperCase() == 'OR') {
      return [for (final part in parts) ...part];
    }
    var result = [<QueryCond>[]];
    for (final part in parts) {
      result = _and(result, part);
    }
    return result;
  }
  return [
    [QueryCond(_fieldName(filter['fieldPath']), op, filter['value'])],
  ];
}

/// Records queries; see the file comment.
class ParticipantQuerySpy extends Fake implements FirebaseFirestore {
  ParticipantQuerySpy(this.inner);

  final FirebaseFirestore inner;

  /// Every query run so far (get or snapshots), in order.
  final List<RecordedQuery> queries = [];

  /// When true, writes the rules would deny because of `actions.managerId`
  /// fail with permission-denied, as if the plan's manager had changed since
  /// the app read it.
  bool denyActionManagerStamp = false;

  /// Queries for which this returns true fail (get and snapshots) with
  /// failed-precondition, like a query whose composite index isn't built.
  bool Function(RecordedQuery query)? failWhen;

  List<String> get shapes => [for (final q in queries) q.shape];

  /// The recorded queries firestore.rules.next would deny for [me].
  List<String> rulesNextViolations(String me) => [
    for (final q in queries)
      if (q.rulesNextViolation(me) case final why?) '${q.shape}: $why',
  ];

  void clear() => queries.clear();

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _SpyCollection(
      this,
      collectionPath,
      inner.collection(collectionPath),
    );
  }

  @override
  WriteBatch batch() => _SpyBatch(this, inner.batch());

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    return inner.runTransaction(
      transactionHandler,
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }

  static FirebaseException _denied() => FirebaseException(
    plugin: 'cloud_firestore',
    code: 'permission-denied',
    message: 'managerId is not the plan manager',
  );
}

class _SpyQuery extends Fake implements Query<Map<String, dynamic>> {
  _SpyQuery(
    this._spy,
    this._collection,
    this._delegate, {
    List<List<QueryCond>>? disjuncts,
    List<String> orderBy = const [],
    int? limit,
  }) : _disjuncts = disjuncts ?? [<QueryCond>[]],
       _orderBy = orderBy,
       _limit = limit;

  final ParticipantQuerySpy _spy;
  final String _collection;
  final Query<Map<String, dynamic>> _delegate;
  final List<List<QueryCond>> _disjuncts;
  final List<String> _orderBy;
  final int? _limit;

  _SpyQuery _next(
    Query<Map<String, dynamic>> delegate, {
    List<List<QueryCond>>? disjuncts,
    List<String>? orderBy,
    int? limit,
  }) => _SpyQuery(
    _spy,
    _collection,
    delegate,
    disjuncts: disjuncts ?? _disjuncts,
    orderBy: orderBy ?? _orderBy,
    limit: limit ?? _limit,
  );

  /// Records the query; true when [ParticipantQuerySpy.failWhen] fails it.
  bool _record() {
    final query = RecordedQuery(
      collection: _collection,
      disjuncts: _disjuncts,
      orderBy: _orderBy,
      limit: _limit,
    );
    _spy.queries.add(query);
    return _spy.failWhen?.call(query) ?? false;
  }

  static FirebaseException _indexMissing() => FirebaseException(
    plugin: 'cloud_firestore',
    code: 'failed-precondition',
    message: 'The query requires an index.',
  );

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    final List<List<QueryCond>> added;
    if (field is Filter) {
      added = _dnf(field.toJson());
    } else {
      final candidates = <(String, Object?)>[
        ('==', isEqualTo),
        ('!=', isNotEqualTo),
        ('<', isLessThan),
        ('<=', isLessThanOrEqualTo),
        ('>', isGreaterThan),
        ('>=', isGreaterThanOrEqualTo),
        ('array-contains', arrayContains),
        ('array-contains-any', arrayContainsAny),
        ('in', whereIn),
        ('not-in', whereNotIn),
        ('is-null', isNull),
      ];
      final (op, value) = candidates.firstWhere(
        (candidate) => candidate.$2 != null,
        orElse: () => ('==', null),
      );
      added = [
        [QueryCond(_fieldName(field), op, value)],
      ];
    }
    return _next(
      _delegate.where(
        field,
        isEqualTo: isEqualTo,
        isNotEqualTo: isNotEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        arrayContains: arrayContains,
        arrayContainsAny: arrayContainsAny,
        whereIn: whereIn,
        whereNotIn: whereNotIn,
        isNull: isNull,
      ),
      disjuncts: _and(_disjuncts, added),
    );
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    return _next(
      _delegate.orderBy(field, descending: descending),
      orderBy: [
        ..._orderBy,
        '${_fieldName(field)}${descending ? ' desc' : ''}',
      ],
    );
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    return _next(_delegate.limit(limit), limit: limit);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) {
    if (_record()) return Future.error(_indexMissing());
    return _delegate.get(options);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    if (_record()) return Stream.error(_indexMissing());
    return _delegate.snapshots(
      includeMetadataChanges: includeMetadataChanges,
      source: source,
    );
  }
}

class _SpyCollection extends _SpyQuery
    implements CollectionReference<Map<String, dynamic>> {
  _SpyCollection(ParticipantQuerySpy spy, String collection, this._reference)
    : super(spy, collection, _reference);

  final CollectionReference<Map<String, dynamic>> _reference;

  @override
  String get id => _reference.id;

  @override
  String get path => _reference.path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _reference.doc(path);

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    if (_spy.denyActionManagerStamp &&
        _collection == 'actions' &&
        data.containsKey('managerId')) {
      throw ParticipantQuerySpy._denied();
    }
    return _reference.add(data);
  }
}

/// Forwards to the real batch; fails the commit like the rules would when
/// [ParticipantQuerySpy.denyActionManagerStamp] is set and an action is
/// created with a `managerId`.
class _SpyBatch extends Fake implements WriteBatch {
  _SpyBatch(this._spy, this._inner);

  final ParticipantQuerySpy _spy;
  final WriteBatch _inner;
  bool _stampsActionManager = false;

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    if (document.parent.id == 'actions' &&
        data is Map &&
        data.containsKey('managerId')) {
      _stampsActionManager = true;
    }
    _inner.set(document, data, options);
  }

  @override
  void update(DocumentReference document, Map<Object, Object?> data) {
    _inner.update(document, data);
  }

  @override
  void delete(DocumentReference document) {
    _inner.delete(document);
  }

  @override
  Future<void> commit() async {
    if (_spy.denyActionManagerStamp && _stampsActionManager) {
      throw ParticipantQuerySpy._denied();
    }
    await _inner.commit();
  }
}
