// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RecipesTable extends Recipes with TableInfo<$RecipesTable, RecipeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _servingsMeta = const VerificationMeta(
    'servings',
  );
  @override
  late final GeneratedColumn<double> servings = GeneratedColumn<double>(
    'servings',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<String> steps = GeneratedColumn<String>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailMeta = const VerificationMeta(
    'thumbnail',
  );
  @override
  late final GeneratedColumn<Uint8List> thumbnail = GeneratedColumn<Uint8List>(
    'thumbnail',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    servings,
    steps,
    sourceUrl,
    thumbnail,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('servings')) {
      context.handle(
        _servingsMeta,
        servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta),
      );
    } else if (isInserting) {
      context.missing(_servingsMeta);
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('thumbnail')) {
      context.handle(
        _thumbnailMeta,
        thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      servings: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}servings'],
      )!,
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}steps'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      thumbnail: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}thumbnail'],
      ),
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class RecipeRow extends DataClass implements Insertable<RecipeRow> {
  final int id;
  final String title;
  final double servings;

  /// JSON-encoded list of step strings.
  final String steps;
  final String? sourceUrl;
  final Uint8List? thumbnail;
  const RecipeRow({
    required this.id,
    required this.title,
    required this.servings,
    required this.steps,
    this.sourceUrl,
    this.thumbnail,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['servings'] = Variable<double>(servings);
    map['steps'] = Variable<String>(steps);
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    if (!nullToAbsent || thumbnail != null) {
      map['thumbnail'] = Variable<Uint8List>(thumbnail);
    }
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      title: Value(title),
      servings: Value(servings),
      steps: Value(steps),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      thumbnail: thumbnail == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnail),
    );
  }

  factory RecipeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      servings: serializer.fromJson<double>(json['servings']),
      steps: serializer.fromJson<String>(json['steps']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      thumbnail: serializer.fromJson<Uint8List?>(json['thumbnail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'servings': serializer.toJson<double>(servings),
      'steps': serializer.toJson<String>(steps),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'thumbnail': serializer.toJson<Uint8List?>(thumbnail),
    };
  }

  RecipeRow copyWith({
    int? id,
    String? title,
    double? servings,
    String? steps,
    Value<String?> sourceUrl = const Value.absent(),
    Value<Uint8List?> thumbnail = const Value.absent(),
  }) => RecipeRow(
    id: id ?? this.id,
    title: title ?? this.title,
    servings: servings ?? this.servings,
    steps: steps ?? this.steps,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    thumbnail: thumbnail.present ? thumbnail.value : this.thumbnail,
  );
  RecipeRow copyWithCompanion(RecipesCompanion data) {
    return RecipeRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      servings: data.servings.present ? data.servings.value : this.servings,
      steps: data.steps.present ? data.steps.value : this.steps,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('servings: $servings, ')
          ..write('steps: $steps, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('thumbnail: $thumbnail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    servings,
    steps,
    sourceUrl,
    $driftBlobEquality.hash(thumbnail),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.servings == this.servings &&
          other.steps == this.steps &&
          other.sourceUrl == this.sourceUrl &&
          $driftBlobEquality.equals(other.thumbnail, this.thumbnail));
}

class RecipesCompanion extends UpdateCompanion<RecipeRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<double> servings;
  final Value<String> steps;
  final Value<String?> sourceUrl;
  final Value<Uint8List?> thumbnail;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.servings = const Value.absent(),
    this.steps = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.thumbnail = const Value.absent(),
  });
  RecipesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required double servings,
    this.steps = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.thumbnail = const Value.absent(),
  }) : title = Value(title),
       servings = Value(servings);
  static Insertable<RecipeRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<double>? servings,
    Expression<String>? steps,
    Expression<String>? sourceUrl,
    Expression<Uint8List>? thumbnail,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (servings != null) 'servings': servings,
      if (steps != null) 'steps': steps,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (thumbnail != null) 'thumbnail': thumbnail,
    });
  }

  RecipesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<double>? servings,
    Value<String>? steps,
    Value<String?>? sourceUrl,
    Value<Uint8List?>? thumbnail,
  }) {
    return RecipesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      servings: servings ?? this.servings,
      steps: steps ?? this.steps,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (servings.present) {
      map['servings'] = Variable<double>(servings.value);
    }
    if (steps.present) {
      map['steps'] = Variable<String>(steps.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<Uint8List>(thumbnail.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('servings: $servings, ')
          ..write('steps: $steps, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('thumbnail: $thumbnail')
          ..write(')'))
        .toString();
  }
}

class $IngredientLinesTable extends IngredientLines
    with TableInfo<$IngredientLinesTable, IngredientLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<int> recipeId = GeneratedColumn<int>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalMeta = const VerificationMeta(
    'original',
  );
  @override
  late final GeneratedColumn<String> original = GeneratedColumn<String>(
    'original',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recipeId,
    position,
    original,
    quantity,
    unit,
    name,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngredientLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('original')) {
      context.handle(
        _originalMeta,
        original.isAcceptableOrUnknown(data['original']!, _originalMeta),
      );
    } else if (isInserting) {
      context.missing(_originalMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipe_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      original: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
    );
  }

  @override
  $IngredientLinesTable createAlias(String alias) {
    return $IngredientLinesTable(attachedDatabase, alias);
  }
}

class IngredientLineRow extends DataClass
    implements Insertable<IngredientLineRow> {
  final int id;
  final int recipeId;
  final int position;
  final String original;
  final double? quantity;
  final String? unit;
  final String? name;
  const IngredientLineRow({
    required this.id,
    required this.recipeId,
    required this.position,
    required this.original,
    this.quantity,
    this.unit,
    this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recipe_id'] = Variable<int>(recipeId);
    map['position'] = Variable<int>(position);
    map['original'] = Variable<String>(original);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    return map;
  }

  IngredientLinesCompanion toCompanion(bool nullToAbsent) {
    return IngredientLinesCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      position: Value(position),
      original: Value(original),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory IngredientLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientLineRow(
      id: serializer.fromJson<int>(json['id']),
      recipeId: serializer.fromJson<int>(json['recipeId']),
      position: serializer.fromJson<int>(json['position']),
      original: serializer.fromJson<String>(json['original']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recipeId': serializer.toJson<int>(recipeId),
      'position': serializer.toJson<int>(position),
      'original': serializer.toJson<String>(original),
      'quantity': serializer.toJson<double?>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'name': serializer.toJson<String?>(name),
    };
  }

  IngredientLineRow copyWith({
    int? id,
    int? recipeId,
    int? position,
    String? original,
    Value<double?> quantity = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> name = const Value.absent(),
  }) => IngredientLineRow(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    position: position ?? this.position,
    original: original ?? this.original,
    quantity: quantity.present ? quantity.value : this.quantity,
    unit: unit.present ? unit.value : this.unit,
    name: name.present ? name.value : this.name,
  );
  IngredientLineRow copyWithCompanion(IngredientLinesCompanion data) {
    return IngredientLineRow(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      position: data.position.present ? data.position.value : this.position,
      original: data.original.present ? data.original.value : this.original,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientLineRow(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('position: $position, ')
          ..write('original: $original, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recipeId, position, original, quantity, unit, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientLineRow &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.position == this.position &&
          other.original == this.original &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.name == this.name);
}

class IngredientLinesCompanion extends UpdateCompanion<IngredientLineRow> {
  final Value<int> id;
  final Value<int> recipeId;
  final Value<int> position;
  final Value<String> original;
  final Value<double?> quantity;
  final Value<String?> unit;
  final Value<String?> name;
  const IngredientLinesCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.position = const Value.absent(),
    this.original = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.name = const Value.absent(),
  });
  IngredientLinesCompanion.insert({
    this.id = const Value.absent(),
    required int recipeId,
    required int position,
    required String original,
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.name = const Value.absent(),
  }) : recipeId = Value(recipeId),
       position = Value(position),
       original = Value(original);
  static Insertable<IngredientLineRow> custom({
    Expression<int>? id,
    Expression<int>? recipeId,
    Expression<int>? position,
    Expression<String>? original,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (position != null) 'position': position,
      if (original != null) 'original': original,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (name != null) 'name': name,
    });
  }

  IngredientLinesCompanion copyWith({
    Value<int>? id,
    Value<int>? recipeId,
    Value<int>? position,
    Value<String>? original,
    Value<double?>? quantity,
    Value<String?>? unit,
    Value<String?>? name,
  }) {
    return IngredientLinesCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      position: position ?? this.position,
      original: original ?? this.original,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<int>(recipeId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (original.present) {
      map['original'] = Variable<String>(original.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientLinesCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('position: $position, ')
          ..write('original: $original, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $SlotItemsTable extends SlotItems
    with TableInfo<$SlotItemsTable, SlotItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SlotItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealMeta = const VerificationMeta('meal');
  @override
  late final GeneratedColumn<int> meal = GeneratedColumn<int>(
    'meal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _freeTextMeta = const VerificationMeta(
    'freeText',
  );
  @override
  late final GeneratedColumn<String> freeText = GeneratedColumn<String>(
    'free_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<int> recipeId = GeneratedColumn<int>(
    'recipe_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id)',
    ),
  );
  static const VerificationMeta _servingsMeta = const VerificationMeta(
    'servings',
  );
  @override
  late final GeneratedColumn<double> servings = GeneratedColumn<double>(
    'servings',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    meal,
    position,
    freeText,
    recipeId,
    servings,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'slot_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SlotItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('meal')) {
      context.handle(
        _mealMeta,
        meal.isAcceptableOrUnknown(data['meal']!, _mealMeta),
      );
    } else if (isInserting) {
      context.missing(_mealMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('free_text')) {
      context.handle(
        _freeTextMeta,
        freeText.isAcceptableOrUnknown(data['free_text']!, _freeTextMeta),
      );
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    }
    if (data.containsKey('servings')) {
      context.handle(
        _servingsMeta,
        servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SlotItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SlotItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      meal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meal'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      freeText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}free_text'],
      ),
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipe_id'],
      ),
      servings: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}servings'],
      ),
    );
  }

  @override
  $SlotItemsTable createAlias(String alias) {
    return $SlotItemsTable(attachedDatabase, alias);
  }
}

class SlotItemRow extends DataClass implements Insertable<SlotItemRow> {
  final int id;

  /// Calendar date as yyyymmdd.
  final int date;

  /// `MealType.index`.
  final int meal;
  final int position;
  final String? freeText;
  final int? recipeId;
  final double? servings;
  const SlotItemRow({
    required this.id,
    required this.date,
    required this.meal,
    required this.position,
    this.freeText,
    this.recipeId,
    this.servings,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<int>(date);
    map['meal'] = Variable<int>(meal);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || freeText != null) {
      map['free_text'] = Variable<String>(freeText);
    }
    if (!nullToAbsent || recipeId != null) {
      map['recipe_id'] = Variable<int>(recipeId);
    }
    if (!nullToAbsent || servings != null) {
      map['servings'] = Variable<double>(servings);
    }
    return map;
  }

  SlotItemsCompanion toCompanion(bool nullToAbsent) {
    return SlotItemsCompanion(
      id: Value(id),
      date: Value(date),
      meal: Value(meal),
      position: Value(position),
      freeText: freeText == null && nullToAbsent
          ? const Value.absent()
          : Value(freeText),
      recipeId: recipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(recipeId),
      servings: servings == null && nullToAbsent
          ? const Value.absent()
          : Value(servings),
    );
  }

  factory SlotItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SlotItemRow(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<int>(json['date']),
      meal: serializer.fromJson<int>(json['meal']),
      position: serializer.fromJson<int>(json['position']),
      freeText: serializer.fromJson<String?>(json['freeText']),
      recipeId: serializer.fromJson<int?>(json['recipeId']),
      servings: serializer.fromJson<double?>(json['servings']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<int>(date),
      'meal': serializer.toJson<int>(meal),
      'position': serializer.toJson<int>(position),
      'freeText': serializer.toJson<String?>(freeText),
      'recipeId': serializer.toJson<int?>(recipeId),
      'servings': serializer.toJson<double?>(servings),
    };
  }

  SlotItemRow copyWith({
    int? id,
    int? date,
    int? meal,
    int? position,
    Value<String?> freeText = const Value.absent(),
    Value<int?> recipeId = const Value.absent(),
    Value<double?> servings = const Value.absent(),
  }) => SlotItemRow(
    id: id ?? this.id,
    date: date ?? this.date,
    meal: meal ?? this.meal,
    position: position ?? this.position,
    freeText: freeText.present ? freeText.value : this.freeText,
    recipeId: recipeId.present ? recipeId.value : this.recipeId,
    servings: servings.present ? servings.value : this.servings,
  );
  SlotItemRow copyWithCompanion(SlotItemsCompanion data) {
    return SlotItemRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      meal: data.meal.present ? data.meal.value : this.meal,
      position: data.position.present ? data.position.value : this.position,
      freeText: data.freeText.present ? data.freeText.value : this.freeText,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      servings: data.servings.present ? data.servings.value : this.servings,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SlotItemRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('meal: $meal, ')
          ..write('position: $position, ')
          ..write('freeText: $freeText, ')
          ..write('recipeId: $recipeId, ')
          ..write('servings: $servings')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, meal, position, freeText, recipeId, servings);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SlotItemRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.meal == this.meal &&
          other.position == this.position &&
          other.freeText == this.freeText &&
          other.recipeId == this.recipeId &&
          other.servings == this.servings);
}

class SlotItemsCompanion extends UpdateCompanion<SlotItemRow> {
  final Value<int> id;
  final Value<int> date;
  final Value<int> meal;
  final Value<int> position;
  final Value<String?> freeText;
  final Value<int?> recipeId;
  final Value<double?> servings;
  const SlotItemsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.meal = const Value.absent(),
    this.position = const Value.absent(),
    this.freeText = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.servings = const Value.absent(),
  });
  SlotItemsCompanion.insert({
    this.id = const Value.absent(),
    required int date,
    required int meal,
    required int position,
    this.freeText = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.servings = const Value.absent(),
  }) : date = Value(date),
       meal = Value(meal),
       position = Value(position);
  static Insertable<SlotItemRow> custom({
    Expression<int>? id,
    Expression<int>? date,
    Expression<int>? meal,
    Expression<int>? position,
    Expression<String>? freeText,
    Expression<int>? recipeId,
    Expression<double>? servings,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (meal != null) 'meal': meal,
      if (position != null) 'position': position,
      if (freeText != null) 'free_text': freeText,
      if (recipeId != null) 'recipe_id': recipeId,
      if (servings != null) 'servings': servings,
    });
  }

  SlotItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? date,
    Value<int>? meal,
    Value<int>? position,
    Value<String?>? freeText,
    Value<int?>? recipeId,
    Value<double?>? servings,
  }) {
    return SlotItemsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      meal: meal ?? this.meal,
      position: position ?? this.position,
      freeText: freeText ?? this.freeText,
      recipeId: recipeId ?? this.recipeId,
      servings: servings ?? this.servings,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (meal.present) {
      map['meal'] = Variable<int>(meal.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (freeText.present) {
      map['free_text'] = Variable<String>(freeText.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<int>(recipeId.value);
    }
    if (servings.present) {
      map['servings'] = Variable<double>(servings.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SlotItemsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('meal: $meal, ')
          ..write('position: $position, ')
          ..write('freeText: $freeText, ')
          ..write('recipeId: $recipeId, ')
          ..write('servings: $servings')
          ..write(')'))
        .toString();
  }
}

class $ShoppingChecksTable extends ShoppingChecks
    with TableInfo<$ShoppingChecksTable, ShoppingCheckRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingChecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _weekMeta = const VerificationMeta('week');
  @override
  late final GeneratedColumn<int> week = GeneratedColumn<int>(
    'week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryKeyMeta = const VerificationMeta(
    'entryKey',
  );
  @override
  late final GeneratedColumn<String> entryKey = GeneratedColumn<String>(
    'entry_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkedQuantityMeta = const VerificationMeta(
    'checkedQuantity',
  );
  @override
  late final GeneratedColumn<double> checkedQuantity = GeneratedColumn<double>(
    'checked_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [week, entryKey, checkedQuantity];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_checks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingCheckRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('week')) {
      context.handle(
        _weekMeta,
        week.isAcceptableOrUnknown(data['week']!, _weekMeta),
      );
    } else if (isInserting) {
      context.missing(_weekMeta);
    }
    if (data.containsKey('entry_key')) {
      context.handle(
        _entryKeyMeta,
        entryKey.isAcceptableOrUnknown(data['entry_key']!, _entryKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_entryKeyMeta);
    }
    if (data.containsKey('checked_quantity')) {
      context.handle(
        _checkedQuantityMeta,
        checkedQuantity.isAcceptableOrUnknown(
          data['checked_quantity']!,
          _checkedQuantityMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {week, entryKey};
  @override
  ShoppingCheckRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingCheckRow(
      week: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week'],
      )!,
      entryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_key'],
      )!,
      checkedQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}checked_quantity'],
      ),
    );
  }

  @override
  $ShoppingChecksTable createAlias(String alias) {
    return $ShoppingChecksTable(attachedDatabase, alias);
  }
}

class ShoppingCheckRow extends DataClass
    implements Insertable<ShoppingCheckRow> {
  /// Monday of the week, yyyymmdd.
  final int week;
  final String entryKey;

  /// Quantity in base units when checked, null for unquantified entries.
  final double? checkedQuantity;
  const ShoppingCheckRow({
    required this.week,
    required this.entryKey,
    this.checkedQuantity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['week'] = Variable<int>(week);
    map['entry_key'] = Variable<String>(entryKey);
    if (!nullToAbsent || checkedQuantity != null) {
      map['checked_quantity'] = Variable<double>(checkedQuantity);
    }
    return map;
  }

  ShoppingChecksCompanion toCompanion(bool nullToAbsent) {
    return ShoppingChecksCompanion(
      week: Value(week),
      entryKey: Value(entryKey),
      checkedQuantity: checkedQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedQuantity),
    );
  }

  factory ShoppingCheckRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingCheckRow(
      week: serializer.fromJson<int>(json['week']),
      entryKey: serializer.fromJson<String>(json['entryKey']),
      checkedQuantity: serializer.fromJson<double?>(json['checkedQuantity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'week': serializer.toJson<int>(week),
      'entryKey': serializer.toJson<String>(entryKey),
      'checkedQuantity': serializer.toJson<double?>(checkedQuantity),
    };
  }

  ShoppingCheckRow copyWith({
    int? week,
    String? entryKey,
    Value<double?> checkedQuantity = const Value.absent(),
  }) => ShoppingCheckRow(
    week: week ?? this.week,
    entryKey: entryKey ?? this.entryKey,
    checkedQuantity: checkedQuantity.present
        ? checkedQuantity.value
        : this.checkedQuantity,
  );
  ShoppingCheckRow copyWithCompanion(ShoppingChecksCompanion data) {
    return ShoppingCheckRow(
      week: data.week.present ? data.week.value : this.week,
      entryKey: data.entryKey.present ? data.entryKey.value : this.entryKey,
      checkedQuantity: data.checkedQuantity.present
          ? data.checkedQuantity.value
          : this.checkedQuantity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingCheckRow(')
          ..write('week: $week, ')
          ..write('entryKey: $entryKey, ')
          ..write('checkedQuantity: $checkedQuantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(week, entryKey, checkedQuantity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingCheckRow &&
          other.week == this.week &&
          other.entryKey == this.entryKey &&
          other.checkedQuantity == this.checkedQuantity);
}

class ShoppingChecksCompanion extends UpdateCompanion<ShoppingCheckRow> {
  final Value<int> week;
  final Value<String> entryKey;
  final Value<double?> checkedQuantity;
  final Value<int> rowid;
  const ShoppingChecksCompanion({
    this.week = const Value.absent(),
    this.entryKey = const Value.absent(),
    this.checkedQuantity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingChecksCompanion.insert({
    required int week,
    required String entryKey,
    this.checkedQuantity = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : week = Value(week),
       entryKey = Value(entryKey);
  static Insertable<ShoppingCheckRow> custom({
    Expression<int>? week,
    Expression<String>? entryKey,
    Expression<double>? checkedQuantity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (week != null) 'week': week,
      if (entryKey != null) 'entry_key': entryKey,
      if (checkedQuantity != null) 'checked_quantity': checkedQuantity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingChecksCompanion copyWith({
    Value<int>? week,
    Value<String>? entryKey,
    Value<double?>? checkedQuantity,
    Value<int>? rowid,
  }) {
    return ShoppingChecksCompanion(
      week: week ?? this.week,
      entryKey: entryKey ?? this.entryKey,
      checkedQuantity: checkedQuantity ?? this.checkedQuantity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (week.present) {
      map['week'] = Variable<int>(week.value);
    }
    if (entryKey.present) {
      map['entry_key'] = Variable<String>(entryKey.value);
    }
    if (checkedQuantity.present) {
      map['checked_quantity'] = Variable<double>(checkedQuantity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingChecksCompanion(')
          ..write('week: $week, ')
          ..write('entryKey: $entryKey, ')
          ..write('checkedQuantity: $checkedQuantity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ManualShoppingItemsTable extends ManualShoppingItems
    with TableInfo<$ManualShoppingItemsTable, ManualShoppingItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManualShoppingItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _weekMeta = const VerificationMeta('week');
  @override
  late final GeneratedColumn<int> week = GeneratedColumn<int>(
    'week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkedMeta = const VerificationMeta(
    'checked',
  );
  @override
  late final GeneratedColumn<bool> checked = GeneratedColumn<bool>(
    'checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, week, label, checked];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manual_shopping_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ManualShoppingItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('week')) {
      context.handle(
        _weekMeta,
        week.isAcceptableOrUnknown(data['week']!, _weekMeta),
      );
    } else if (isInserting) {
      context.missing(_weekMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('checked')) {
      context.handle(
        _checkedMeta,
        checked.isAcceptableOrUnknown(data['checked']!, _checkedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ManualShoppingItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ManualShoppingItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      week: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      checked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}checked'],
      )!,
    );
  }

  @override
  $ManualShoppingItemsTable createAlias(String alias) {
    return $ManualShoppingItemsTable(attachedDatabase, alias);
  }
}

class ManualShoppingItemRow extends DataClass
    implements Insertable<ManualShoppingItemRow> {
  final int id;
  final int week;
  final String label;
  final bool checked;
  const ManualShoppingItemRow({
    required this.id,
    required this.week,
    required this.label,
    required this.checked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['week'] = Variable<int>(week);
    map['label'] = Variable<String>(label);
    map['checked'] = Variable<bool>(checked);
    return map;
  }

  ManualShoppingItemsCompanion toCompanion(bool nullToAbsent) {
    return ManualShoppingItemsCompanion(
      id: Value(id),
      week: Value(week),
      label: Value(label),
      checked: Value(checked),
    );
  }

  factory ManualShoppingItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ManualShoppingItemRow(
      id: serializer.fromJson<int>(json['id']),
      week: serializer.fromJson<int>(json['week']),
      label: serializer.fromJson<String>(json['label']),
      checked: serializer.fromJson<bool>(json['checked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'week': serializer.toJson<int>(week),
      'label': serializer.toJson<String>(label),
      'checked': serializer.toJson<bool>(checked),
    };
  }

  ManualShoppingItemRow copyWith({
    int? id,
    int? week,
    String? label,
    bool? checked,
  }) => ManualShoppingItemRow(
    id: id ?? this.id,
    week: week ?? this.week,
    label: label ?? this.label,
    checked: checked ?? this.checked,
  );
  ManualShoppingItemRow copyWithCompanion(ManualShoppingItemsCompanion data) {
    return ManualShoppingItemRow(
      id: data.id.present ? data.id.value : this.id,
      week: data.week.present ? data.week.value : this.week,
      label: data.label.present ? data.label.value : this.label,
      checked: data.checked.present ? data.checked.value : this.checked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ManualShoppingItemRow(')
          ..write('id: $id, ')
          ..write('week: $week, ')
          ..write('label: $label, ')
          ..write('checked: $checked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, week, label, checked);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManualShoppingItemRow &&
          other.id == this.id &&
          other.week == this.week &&
          other.label == this.label &&
          other.checked == this.checked);
}

class ManualShoppingItemsCompanion
    extends UpdateCompanion<ManualShoppingItemRow> {
  final Value<int> id;
  final Value<int> week;
  final Value<String> label;
  final Value<bool> checked;
  const ManualShoppingItemsCompanion({
    this.id = const Value.absent(),
    this.week = const Value.absent(),
    this.label = const Value.absent(),
    this.checked = const Value.absent(),
  });
  ManualShoppingItemsCompanion.insert({
    this.id = const Value.absent(),
    required int week,
    required String label,
    this.checked = const Value.absent(),
  }) : week = Value(week),
       label = Value(label);
  static Insertable<ManualShoppingItemRow> custom({
    Expression<int>? id,
    Expression<int>? week,
    Expression<String>? label,
    Expression<bool>? checked,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (week != null) 'week': week,
      if (label != null) 'label': label,
      if (checked != null) 'checked': checked,
    });
  }

  ManualShoppingItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? week,
    Value<String>? label,
    Value<bool>? checked,
  }) {
    return ManualShoppingItemsCompanion(
      id: id ?? this.id,
      week: week ?? this.week,
      label: label ?? this.label,
      checked: checked ?? this.checked,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (week.present) {
      map['week'] = Variable<int>(week.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (checked.present) {
      map['checked'] = Variable<bool>(checked.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManualShoppingItemsCompanion(')
          ..write('id: $id, ')
          ..write('week: $week, ')
          ..write('label: $label, ')
          ..write('checked: $checked')
          ..write(')'))
        .toString();
  }
}

class $IngredientAliasesTable extends IngredientAliases
    with TableInfo<$IngredientAliasesTable, IngredientAliasRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fromNameMeta = const VerificationMeta(
    'fromName',
  );
  @override
  late final GeneratedColumn<String> fromName = GeneratedColumn<String>(
    'from_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toNameMeta = const VerificationMeta('toName');
  @override
  late final GeneratedColumn<String> toName = GeneratedColumn<String>(
    'to_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [fromName, toName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngredientAliasRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('from_name')) {
      context.handle(
        _fromNameMeta,
        fromName.isAcceptableOrUnknown(data['from_name']!, _fromNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fromNameMeta);
    }
    if (data.containsKey('to_name')) {
      context.handle(
        _toNameMeta,
        toName.isAcceptableOrUnknown(data['to_name']!, _toNameMeta),
      );
    } else if (isInserting) {
      context.missing(_toNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fromName};
  @override
  IngredientAliasRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientAliasRow(
      fromName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_name'],
      )!,
      toName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_name'],
      )!,
    );
  }

  @override
  $IngredientAliasesTable createAlias(String alias) {
    return $IngredientAliasesTable(attachedDatabase, alias);
  }
}

class IngredientAliasRow extends DataClass
    implements Insertable<IngredientAliasRow> {
  final String fromName;
  final String toName;
  const IngredientAliasRow({required this.fromName, required this.toName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['from_name'] = Variable<String>(fromName);
    map['to_name'] = Variable<String>(toName);
    return map;
  }

  IngredientAliasesCompanion toCompanion(bool nullToAbsent) {
    return IngredientAliasesCompanion(
      fromName: Value(fromName),
      toName: Value(toName),
    );
  }

  factory IngredientAliasRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientAliasRow(
      fromName: serializer.fromJson<String>(json['fromName']),
      toName: serializer.fromJson<String>(json['toName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fromName': serializer.toJson<String>(fromName),
      'toName': serializer.toJson<String>(toName),
    };
  }

  IngredientAliasRow copyWith({String? fromName, String? toName}) =>
      IngredientAliasRow(
        fromName: fromName ?? this.fromName,
        toName: toName ?? this.toName,
      );
  IngredientAliasRow copyWithCompanion(IngredientAliasesCompanion data) {
    return IngredientAliasRow(
      fromName: data.fromName.present ? data.fromName.value : this.fromName,
      toName: data.toName.present ? data.toName.value : this.toName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientAliasRow(')
          ..write('fromName: $fromName, ')
          ..write('toName: $toName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fromName, toName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientAliasRow &&
          other.fromName == this.fromName &&
          other.toName == this.toName);
}

class IngredientAliasesCompanion extends UpdateCompanion<IngredientAliasRow> {
  final Value<String> fromName;
  final Value<String> toName;
  final Value<int> rowid;
  const IngredientAliasesCompanion({
    this.fromName = const Value.absent(),
    this.toName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientAliasesCompanion.insert({
    required String fromName,
    required String toName,
    this.rowid = const Value.absent(),
  }) : fromName = Value(fromName),
       toName = Value(toName);
  static Insertable<IngredientAliasRow> custom({
    Expression<String>? fromName,
    Expression<String>? toName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fromName != null) 'from_name': fromName,
      if (toName != null) 'to_name': toName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientAliasesCompanion copyWith({
    Value<String>? fromName,
    Value<String>? toName,
    Value<int>? rowid,
  }) {
    return IngredientAliasesCompanion(
      fromName: fromName ?? this.fromName,
      toName: toName ?? this.toName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fromName.present) {
      map['from_name'] = Variable<String>(fromName.value);
    }
    if (toName.present) {
      map['to_name'] = Variable<String>(toName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientAliasesCompanion(')
          ..write('fromName: $fromName, ')
          ..write('toName: $toName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SectionOverridesTable extends SectionOverrides
    with TableInfo<$SectionOverridesTable, SectionOverrideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SectionOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<int> section = GeneratedColumn<int>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, section];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'section_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<SectionOverrideRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  SectionOverrideRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SectionOverrideRow(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section'],
      )!,
    );
  }

  @override
  $SectionOverridesTable createAlias(String alias) {
    return $SectionOverridesTable(attachedDatabase, alias);
  }
}

class SectionOverrideRow extends DataClass
    implements Insertable<SectionOverrideRow> {
  final String name;

  /// `StoreSection.index`.
  final int section;
  const SectionOverrideRow({required this.name, required this.section});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['section'] = Variable<int>(section);
    return map;
  }

  SectionOverridesCompanion toCompanion(bool nullToAbsent) {
    return SectionOverridesCompanion(
      name: Value(name),
      section: Value(section),
    );
  }

  factory SectionOverrideRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SectionOverrideRow(
      name: serializer.fromJson<String>(json['name']),
      section: serializer.fromJson<int>(json['section']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'section': serializer.toJson<int>(section),
    };
  }

  SectionOverrideRow copyWith({String? name, int? section}) =>
      SectionOverrideRow(
        name: name ?? this.name,
        section: section ?? this.section,
      );
  SectionOverrideRow copyWithCompanion(SectionOverridesCompanion data) {
    return SectionOverrideRow(
      name: data.name.present ? data.name.value : this.name,
      section: data.section.present ? data.section.value : this.section,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SectionOverrideRow(')
          ..write('name: $name, ')
          ..write('section: $section')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, section);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SectionOverrideRow &&
          other.name == this.name &&
          other.section == this.section);
}

class SectionOverridesCompanion extends UpdateCompanion<SectionOverrideRow> {
  final Value<String> name;
  final Value<int> section;
  final Value<int> rowid;
  const SectionOverridesCompanion({
    this.name = const Value.absent(),
    this.section = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SectionOverridesCompanion.insert({
    required String name,
    required int section,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       section = Value(section);
  static Insertable<SectionOverrideRow> custom({
    Expression<String>? name,
    Expression<int>? section,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (section != null) 'section': section,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SectionOverridesCompanion copyWith({
    Value<String>? name,
    Value<int>? section,
    Value<int>? rowid,
  }) {
    return SectionOverridesCompanion(
      name: name ?? this.name,
      section: section ?? this.section,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (section.present) {
      map['section'] = Variable<int>(section.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectionOverridesCompanion(')
          ..write('name: $name, ')
          ..write('section: $section, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $IngredientLinesTable ingredientLines = $IngredientLinesTable(
    this,
  );
  late final $SlotItemsTable slotItems = $SlotItemsTable(this);
  late final $ShoppingChecksTable shoppingChecks = $ShoppingChecksTable(this);
  late final $ManualShoppingItemsTable manualShoppingItems =
      $ManualShoppingItemsTable(this);
  late final $IngredientAliasesTable ingredientAliases =
      $IngredientAliasesTable(this);
  late final $SectionOverridesTable sectionOverrides = $SectionOverridesTable(
    this,
  );
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index ingredientLinesRecipe = Index(
    'ingredient_lines_recipe',
    'CREATE INDEX ingredient_lines_recipe ON ingredient_lines (recipe_id)',
  );
  late final Index slotItemsDate = Index(
    'slot_items_date',
    'CREATE INDEX slot_items_date ON slot_items (date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    recipes,
    ingredientLines,
    slotItems,
    shoppingChecks,
    manualShoppingItems,
    ingredientAliases,
    sectionOverrides,
    settings,
    ingredientLinesRecipe,
    slotItemsDate,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ingredient_lines', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$RecipesTableCreateCompanionBuilder = RecipesCompanion Function({
  Value<int> id,
  required String title,
  required double servings,
  Value<String> steps,
  Value<String?> sourceUrl,
  Value<Uint8List?> thumbnail,
});
typedef $$RecipesTableUpdateCompanionBuilder = RecipesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<double> servings,
  Value<String> steps,
  Value<String?> sourceUrl,
  Value<Uint8List?> thumbnail,
});

final class $$RecipesTableReferences
    extends BaseReferences<_$AppDatabase, $RecipesTable, RecipeRow> {
  $$RecipesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IngredientLinesTable, List<IngredientLineRow>>
  _ingredientLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ingredientLines,
    aliasName: 'recipes__id__ingredient_lines__recipe_id',
  );

  $$IngredientLinesTableProcessedTableManager get ingredientLinesRefs {
    final manager = $$IngredientLinesTableTableManager(
      $_db,
      $_db.ingredientLines,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ingredientLinesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SlotItemsTable, List<SlotItemRow>>
  _slotItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.slotItems,
    aliasName: 'recipes__id__slot_items__recipe_id',
  );

  $$SlotItemsTableProcessedTableManager get slotItemsRefs {
    final manager = $$SlotItemsTableTableManager(
      $_db,
      $_db.slotItems,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_slotItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ingredientLinesRefs(
    Expression<bool> Function($$IngredientLinesTableFilterComposer f) f,
  ) {
    final $$IngredientLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ingredientLines,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientLinesTableFilterComposer(
            $db: $db,
            $table: $db.ingredientLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> slotItemsRefs(
    Expression<bool> Function($$SlotItemsTableFilterComposer f) f,
  ) {
    final $$SlotItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.slotItems,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SlotItemsTableFilterComposer(
            $db: $db,
            $table: $db.slotItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  GeneratedColumn<String> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<Uint8List> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  Expression<T> ingredientLinesRefs<T extends Object>(
    Expression<T> Function($$IngredientLinesTableAnnotationComposer a) f,
  ) {
    final $$IngredientLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ingredientLines,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.ingredientLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> slotItemsRefs<T extends Object>(
    Expression<T> Function($$SlotItemsTableAnnotationComposer a) f,
  ) {
    final $$SlotItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.slotItems,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SlotItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.slotItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipesTable,
          RecipeRow,
          $$RecipesTableFilterComposer,
          $$RecipesTableOrderingComposer,
          $$RecipesTableAnnotationComposer,
          $$RecipesTableCreateCompanionBuilder,
          $$RecipesTableUpdateCompanionBuilder,
          (RecipeRow, $$RecipesTableReferences),
          RecipeRow,
          PrefetchHooks Function({bool ingredientLinesRefs, bool slotItemsRefs})
        > {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<double> servings = const Value.absent(),
                Value<String> steps = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<Uint8List?> thumbnail = const Value.absent(),
              }) => RecipesCompanion(
                id: id,
                title: title,
                servings: servings,
                steps: steps,
                sourceUrl: sourceUrl,
                thumbnail: thumbnail,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required double servings,
                Value<String> steps = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<Uint8List?> thumbnail = const Value.absent(),
              }) => RecipesCompanion.insert(
                id: id,
                title: title,
                servings: servings,
                steps: steps,
                sourceUrl: sourceUrl,
                thumbnail: thumbnail,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecipesTable, RecipeRow>(table),
                  $$RecipesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({ingredientLinesRefs = false, slotItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ingredientLinesRefs) db.ingredientLines,
                    if (slotItemsRefs) db.slotItems,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ingredientLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          RecipeRow,
                          $RecipesTable,
                          IngredientLineRow,
                          $IngredientLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._ingredientLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).ingredientLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'recipe_id',
                          typedResults: items,
                        ),
                      if (slotItemsRefs)
                        await $_getPrefetchedDataByColumns<
                          RecipeRow,
                          $RecipesTable,
                          SlotItemRow,
                          $SlotItemsTable
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._slotItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).slotItemsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'recipe_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipesTable,
      RecipeRow,
      $$RecipesTableFilterComposer,
      $$RecipesTableOrderingComposer,
      $$RecipesTableAnnotationComposer,
      $$RecipesTableCreateCompanionBuilder,
      $$RecipesTableUpdateCompanionBuilder,
      (RecipeRow, $$RecipesTableReferences),
      RecipeRow,
      PrefetchHooks Function({bool ingredientLinesRefs, bool slotItemsRefs})
    >;
typedef $$IngredientLinesTableCreateCompanionBuilder =
    IngredientLinesCompanion Function({
      Value<int> id,
      required int recipeId,
      required int position,
      required String original,
      Value<double?> quantity,
      Value<String?> unit,
      Value<String?> name,
    });
typedef $$IngredientLinesTableUpdateCompanionBuilder =
    IngredientLinesCompanion Function({
      Value<int> id,
      Value<int> recipeId,
      Value<int> position,
      Value<String> original,
      Value<double?> quantity,
      Value<String?> unit,
      Value<String?> name,
    });

final class $$IngredientLinesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $IngredientLinesTable,
          IngredientLineRow
        > {
  $$IngredientLinesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('ingredient_lines__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<int>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IngredientLinesTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientLinesTable> {
  $$IngredientLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get original => $composableBuilder(
    column: $table.original,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientLinesTable> {
  $$IngredientLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get original => $composableBuilder(
    column: $table.original,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientLinesTable> {
  $$IngredientLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get original =>
      $composableBuilder(column: $table.original, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientLinesTable,
          IngredientLineRow,
          $$IngredientLinesTableFilterComposer,
          $$IngredientLinesTableOrderingComposer,
          $$IngredientLinesTableAnnotationComposer,
          $$IngredientLinesTableCreateCompanionBuilder,
          $$IngredientLinesTableUpdateCompanionBuilder,
          (IngredientLineRow, $$IngredientLinesTableReferences),
          IngredientLineRow,
          PrefetchHooks Function({bool recipeId})
        > {
  $$IngredientLinesTableTableManager(
    _$AppDatabase db,
    $IngredientLinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> recipeId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> original = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> name = const Value.absent(),
              }) => IngredientLinesCompanion(
                id: id,
                recipeId: recipeId,
                position: position,
                original: original,
                quantity: quantity,
                unit: unit,
                name: name,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int recipeId,
                required int position,
                required String original,
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> name = const Value.absent(),
              }) => IngredientLinesCompanion.insert(
                id: id,
                recipeId: recipeId,
                position: position,
                original: original,
                quantity: quantity,
                unit: unit,
                name: name,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IngredientLinesTable, IngredientLineRow>(table),
                  $$IngredientLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.recipeId,
                        referencedTable: $$IngredientLinesTableReferences
                            ._recipeIdTable(db),
                        referencedColumn: $$IngredientLinesTableReferences
                            ._recipeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IngredientLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientLinesTable,
      IngredientLineRow,
      $$IngredientLinesTableFilterComposer,
      $$IngredientLinesTableOrderingComposer,
      $$IngredientLinesTableAnnotationComposer,
      $$IngredientLinesTableCreateCompanionBuilder,
      $$IngredientLinesTableUpdateCompanionBuilder,
      (IngredientLineRow, $$IngredientLinesTableReferences),
      IngredientLineRow,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$SlotItemsTableCreateCompanionBuilder = SlotItemsCompanion Function({
  Value<int> id,
  required int date,
  required int meal,
  required int position,
  Value<String?> freeText,
  Value<int?> recipeId,
  Value<double?> servings,
});
typedef $$SlotItemsTableUpdateCompanionBuilder = SlotItemsCompanion Function({
  Value<int> id,
  Value<int> date,
  Value<int> meal,
  Value<int> position,
  Value<String?> freeText,
  Value<int?> recipeId,
  Value<double?> servings,
});

final class $$SlotItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SlotItemsTable, SlotItemRow> {
  $$SlotItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('slot_items__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager? get recipeId {
    final $_column = $_itemColumn<int>('recipe_id');
    if ($_column == null) return null;
    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SlotItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SlotItemsTable> {
  $$SlotItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get freeText => $composableBuilder(
    column: $table.freeText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SlotItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SlotItemsTable> {
  $$SlotItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get freeText => $composableBuilder(
    column: $table.freeText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SlotItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SlotItemsTable> {
  $$SlotItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get freeText =>
      $composableBuilder(column: $table.freeText, builder: (column) => column);

  GeneratedColumn<double> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SlotItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SlotItemsTable,
          SlotItemRow,
          $$SlotItemsTableFilterComposer,
          $$SlotItemsTableOrderingComposer,
          $$SlotItemsTableAnnotationComposer,
          $$SlotItemsTableCreateCompanionBuilder,
          $$SlotItemsTableUpdateCompanionBuilder,
          (SlotItemRow, $$SlotItemsTableReferences),
          SlotItemRow,
          PrefetchHooks Function({bool recipeId})
        > {
  $$SlotItemsTableTableManager(_$AppDatabase db, $SlotItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SlotItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SlotItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SlotItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<int> meal = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> freeText = const Value.absent(),
                Value<int?> recipeId = const Value.absent(),
                Value<double?> servings = const Value.absent(),
              }) => SlotItemsCompanion(
                id: id,
                date: date,
                meal: meal,
                position: position,
                freeText: freeText,
                recipeId: recipeId,
                servings: servings,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int date,
                required int meal,
                required int position,
                Value<String?> freeText = const Value.absent(),
                Value<int?> recipeId = const Value.absent(),
                Value<double?> servings = const Value.absent(),
              }) => SlotItemsCompanion.insert(
                id: id,
                date: date,
                meal: meal,
                position: position,
                freeText: freeText,
                recipeId: recipeId,
                servings: servings,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SlotItemsTable, SlotItemRow>(table),
                  $$SlotItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.recipeId,
                        referencedTable: $$SlotItemsTableReferences
                            ._recipeIdTable(db),
                        referencedColumn: $$SlotItemsTableReferences
                            ._recipeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SlotItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SlotItemsTable,
      SlotItemRow,
      $$SlotItemsTableFilterComposer,
      $$SlotItemsTableOrderingComposer,
      $$SlotItemsTableAnnotationComposer,
      $$SlotItemsTableCreateCompanionBuilder,
      $$SlotItemsTableUpdateCompanionBuilder,
      (SlotItemRow, $$SlotItemsTableReferences),
      SlotItemRow,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$ShoppingChecksTableCreateCompanionBuilder =
    ShoppingChecksCompanion Function({
      required int week,
      required String entryKey,
      Value<double?> checkedQuantity,
      Value<int> rowid,
    });
typedef $$ShoppingChecksTableUpdateCompanionBuilder =
    ShoppingChecksCompanion Function({
      Value<int> week,
      Value<String> entryKey,
      Value<double?> checkedQuantity,
      Value<int> rowid,
    });

class $$ShoppingChecksTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingChecksTable> {
  $$ShoppingChecksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get week => $composableBuilder(
    column: $table.week,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryKey => $composableBuilder(
    column: $table.entryKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get checkedQuantity => $composableBuilder(
    column: $table.checkedQuantity,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShoppingChecksTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingChecksTable> {
  $$ShoppingChecksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get week => $composableBuilder(
    column: $table.week,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryKey => $composableBuilder(
    column: $table.entryKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get checkedQuantity => $composableBuilder(
    column: $table.checkedQuantity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingChecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingChecksTable> {
  $$ShoppingChecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get week =>
      $composableBuilder(column: $table.week, builder: (column) => column);

  GeneratedColumn<String> get entryKey =>
      $composableBuilder(column: $table.entryKey, builder: (column) => column);

  GeneratedColumn<double> get checkedQuantity => $composableBuilder(
    column: $table.checkedQuantity,
    builder: (column) => column,
  );
}

class $$ShoppingChecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingChecksTable,
          ShoppingCheckRow,
          $$ShoppingChecksTableFilterComposer,
          $$ShoppingChecksTableOrderingComposer,
          $$ShoppingChecksTableAnnotationComposer,
          $$ShoppingChecksTableCreateCompanionBuilder,
          $$ShoppingChecksTableUpdateCompanionBuilder,
          (
            ShoppingCheckRow,
            BaseReferences<
              _$AppDatabase,
              $ShoppingChecksTable,
              ShoppingCheckRow
            >,
          ),
          ShoppingCheckRow,
          PrefetchHooks Function()
        > {
  $$ShoppingChecksTableTableManager(
    _$AppDatabase db,
    $ShoppingChecksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingChecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingChecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingChecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> week = const Value.absent(),
                Value<String> entryKey = const Value.absent(),
                Value<double?> checkedQuantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingChecksCompanion(
                week: week,
                entryKey: entryKey,
                checkedQuantity: checkedQuantity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int week,
                required String entryKey,
                Value<double?> checkedQuantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingChecksCompanion.insert(
                week: week,
                entryKey: entryKey,
                checkedQuantity: checkedQuantity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShoppingChecksTable, ShoppingCheckRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ShoppingChecksTable,
                    ShoppingCheckRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShoppingChecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingChecksTable,
      ShoppingCheckRow,
      $$ShoppingChecksTableFilterComposer,
      $$ShoppingChecksTableOrderingComposer,
      $$ShoppingChecksTableAnnotationComposer,
      $$ShoppingChecksTableCreateCompanionBuilder,
      $$ShoppingChecksTableUpdateCompanionBuilder,
      (
        ShoppingCheckRow,
        BaseReferences<_$AppDatabase, $ShoppingChecksTable, ShoppingCheckRow>,
      ),
      ShoppingCheckRow,
      PrefetchHooks Function()
    >;
typedef $$ManualShoppingItemsTableCreateCompanionBuilder =
    ManualShoppingItemsCompanion Function({
      Value<int> id,
      required int week,
      required String label,
      Value<bool> checked,
    });
typedef $$ManualShoppingItemsTableUpdateCompanionBuilder =
    ManualShoppingItemsCompanion Function({
      Value<int> id,
      Value<int> week,
      Value<String> label,
      Value<bool> checked,
    });

class $$ManualShoppingItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ManualShoppingItemsTable> {
  $$ManualShoppingItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get week => $composableBuilder(
    column: $table.week,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ManualShoppingItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ManualShoppingItemsTable> {
  $$ManualShoppingItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get week => $composableBuilder(
    column: $table.week,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ManualShoppingItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ManualShoppingItemsTable> {
  $$ManualShoppingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get week =>
      $composableBuilder(column: $table.week, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get checked =>
      $composableBuilder(column: $table.checked, builder: (column) => column);
}

class $$ManualShoppingItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ManualShoppingItemsTable,
          ManualShoppingItemRow,
          $$ManualShoppingItemsTableFilterComposer,
          $$ManualShoppingItemsTableOrderingComposer,
          $$ManualShoppingItemsTableAnnotationComposer,
          $$ManualShoppingItemsTableCreateCompanionBuilder,
          $$ManualShoppingItemsTableUpdateCompanionBuilder,
          (
            ManualShoppingItemRow,
            BaseReferences<
              _$AppDatabase,
              $ManualShoppingItemsTable,
              ManualShoppingItemRow
            >,
          ),
          ManualShoppingItemRow,
          PrefetchHooks Function()
        > {
  $$ManualShoppingItemsTableTableManager(
    _$AppDatabase db,
    $ManualShoppingItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManualShoppingItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ManualShoppingItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ManualShoppingItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> week = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<bool> checked = const Value.absent(),
              }) => ManualShoppingItemsCompanion(
                id: id,
                week: week,
                label: label,
                checked: checked,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int week,
                required String label,
                Value<bool> checked = const Value.absent(),
              }) => ManualShoppingItemsCompanion.insert(
                id: id,
                week: week,
                label: label,
                checked: checked,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ManualShoppingItemsTable, ManualShoppingItemRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ManualShoppingItemsTable,
                    ManualShoppingItemRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ManualShoppingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ManualShoppingItemsTable,
      ManualShoppingItemRow,
      $$ManualShoppingItemsTableFilterComposer,
      $$ManualShoppingItemsTableOrderingComposer,
      $$ManualShoppingItemsTableAnnotationComposer,
      $$ManualShoppingItemsTableCreateCompanionBuilder,
      $$ManualShoppingItemsTableUpdateCompanionBuilder,
      (
        ManualShoppingItemRow,
        BaseReferences<
          _$AppDatabase,
          $ManualShoppingItemsTable,
          ManualShoppingItemRow
        >,
      ),
      ManualShoppingItemRow,
      PrefetchHooks Function()
    >;
typedef $$IngredientAliasesTableCreateCompanionBuilder =
    IngredientAliasesCompanion Function({
      required String fromName,
      required String toName,
      Value<int> rowid,
    });
typedef $$IngredientAliasesTableUpdateCompanionBuilder =
    IngredientAliasesCompanion Function({
      Value<String> fromName,
      Value<String> toName,
      Value<int> rowid,
    });

class $$IngredientAliasesTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientAliasesTable> {
  $$IngredientAliasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fromName => $composableBuilder(
    column: $table.fromName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toName => $composableBuilder(
    column: $table.toName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IngredientAliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientAliasesTable> {
  $$IngredientAliasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fromName => $composableBuilder(
    column: $table.fromName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toName => $composableBuilder(
    column: $table.toName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IngredientAliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientAliasesTable> {
  $$IngredientAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fromName =>
      $composableBuilder(column: $table.fromName, builder: (column) => column);

  GeneratedColumn<String> get toName =>
      $composableBuilder(column: $table.toName, builder: (column) => column);
}

class $$IngredientAliasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientAliasesTable,
          IngredientAliasRow,
          $$IngredientAliasesTableFilterComposer,
          $$IngredientAliasesTableOrderingComposer,
          $$IngredientAliasesTableAnnotationComposer,
          $$IngredientAliasesTableCreateCompanionBuilder,
          $$IngredientAliasesTableUpdateCompanionBuilder,
          (
            IngredientAliasRow,
            BaseReferences<
              _$AppDatabase,
              $IngredientAliasesTable,
              IngredientAliasRow
            >,
          ),
          IngredientAliasRow,
          PrefetchHooks Function()
        > {
  $$IngredientAliasesTableTableManager(
    _$AppDatabase db,
    $IngredientAliasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientAliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientAliasesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> fromName = const Value.absent(),
                Value<String> toName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientAliasesCompanion(
                fromName: fromName,
                toName: toName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fromName,
                required String toName,
                Value<int> rowid = const Value.absent(),
              }) => IngredientAliasesCompanion.insert(
                fromName: fromName,
                toName: toName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IngredientAliasesTable, IngredientAliasRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $IngredientAliasesTable,
                    IngredientAliasRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IngredientAliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientAliasesTable,
      IngredientAliasRow,
      $$IngredientAliasesTableFilterComposer,
      $$IngredientAliasesTableOrderingComposer,
      $$IngredientAliasesTableAnnotationComposer,
      $$IngredientAliasesTableCreateCompanionBuilder,
      $$IngredientAliasesTableUpdateCompanionBuilder,
      (
        IngredientAliasRow,
        BaseReferences<
          _$AppDatabase,
          $IngredientAliasesTable,
          IngredientAliasRow
        >,
      ),
      IngredientAliasRow,
      PrefetchHooks Function()
    >;
typedef $$SectionOverridesTableCreateCompanionBuilder =
    SectionOverridesCompanion Function({
      required String name,
      required int section,
      Value<int> rowid,
    });
typedef $$SectionOverridesTableUpdateCompanionBuilder =
    SectionOverridesCompanion Function({
      Value<String> name,
      Value<int> section,
      Value<int> rowid,
    });

class $$SectionOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $SectionOverridesTable> {
  $$SectionOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SectionOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $SectionOverridesTable> {
  $$SectionOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SectionOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SectionOverridesTable> {
  $$SectionOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);
}

class $$SectionOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SectionOverridesTable,
          SectionOverrideRow,
          $$SectionOverridesTableFilterComposer,
          $$SectionOverridesTableOrderingComposer,
          $$SectionOverridesTableAnnotationComposer,
          $$SectionOverridesTableCreateCompanionBuilder,
          $$SectionOverridesTableUpdateCompanionBuilder,
          (
            SectionOverrideRow,
            BaseReferences<
              _$AppDatabase,
              $SectionOverridesTable,
              SectionOverrideRow
            >,
          ),
          SectionOverrideRow,
          PrefetchHooks Function()
        > {
  $$SectionOverridesTableTableManager(
    _$AppDatabase db,
    $SectionOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SectionOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SectionOverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SectionOverridesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<int> section = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SectionOverridesCompanion(
                name: name,
                section: section,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required int section,
                Value<int> rowid = const Value.absent(),
              }) => SectionOverridesCompanion.insert(
                name: name,
                section: section,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SectionOverridesTable, SectionOverrideRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SectionOverridesTable,
                    SectionOverrideRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SectionOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SectionOverridesTable,
      SectionOverrideRow,
      $$SectionOverridesTableFilterComposer,
      $$SectionOverridesTableOrderingComposer,
      $$SectionOverridesTableAnnotationComposer,
      $$SectionOverridesTableCreateCompanionBuilder,
      $$SectionOverridesTableUpdateCompanionBuilder,
      (
        SectionOverrideRow,
        BaseReferences<
          _$AppDatabase,
          $SectionOverridesTable,
          SectionOverrideRow
        >,
      ),
      SectionOverrideRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$IngredientLinesTableTableManager get ingredientLines =>
      $$IngredientLinesTableTableManager(_db, _db.ingredientLines);
  $$SlotItemsTableTableManager get slotItems =>
      $$SlotItemsTableTableManager(_db, _db.slotItems);
  $$ShoppingChecksTableTableManager get shoppingChecks =>
      $$ShoppingChecksTableTableManager(_db, _db.shoppingChecks);
  $$ManualShoppingItemsTableTableManager get manualShoppingItems =>
      $$ManualShoppingItemsTableTableManager(_db, _db.manualShoppingItems);
  $$IngredientAliasesTableTableManager get ingredientAliases =>
      $$IngredientAliasesTableTableManager(_db, _db.ingredientAliases);
  $$SectionOverridesTableTableManager get sectionOverrides =>
      $$SectionOverridesTableTableManager(_db, _db.sectionOverrides);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
