% Parameters
int: S;                                    % Number of shape types
int: M;                                    % Grid height
int: N;                                    % Grid width
int: K = 3;                                % Shape kernel size
array[1..S] of int: ShapeCounts;           % Number of instances of each shape type
int: MaxShapeId = sum(ShapeCounts);        % Total number of shape instances

% Variant data: Variants[shapeType, variantIdx, di, dj]
int: MaxVariants;
array[1..S] of int: NumVariants;           % Number of variants per shape type
array[1..S, 1..MaxVariants, 1..K, 1..K] of int: Variants;

% ShapeId mapping: which shape instance ID corresponds to shape type I, instance J
array[1..S, 1..max(ShapeCounts)] of int: ShapeId;

% Computed: which shape type does each SId belong to
array[1..MaxShapeId] of int: ShapeType;
array[1..MaxShapeId] of int: ShapeInst;

% Decision variables
array[1..MaxShapeId, 1..2] of var int: Pos;
array[1..MaxShapeId, 1..K, 1..K, 1..2] of var int: Idx;
array[1..MaxShapeId] of var int: InstVariant;
array[1..M, 1..N] of var 0..MaxShapeId: Grid;
array[1..MaxShapeId, 1..K, 1..K] of var 0..MaxShapeId: InstCells;

% Pos domains
constraint forall(SId in 1..MaxShapeId) (
    Pos[SId, 1] >= 1 /\ Pos[SId, 1] <= M - K + 1 /\
    Pos[SId, 2] >= 1 /\ Pos[SId, 2] <= N - K + 1
);

% Idx computed from Pos
constraint forall(SId in 1..MaxShapeId, DI in 1..K, DJ in 1..K) (
    Idx[SId, DI, DJ, 1] = Pos[SId, 1] + DI - 1 /\
    Idx[SId, DI, DJ, 2] = Pos[SId, 2] + DJ - 1
);

% InstVariant domains
constraint forall(SId in 1..MaxShapeId) (
    InstVariant[SId] >= 1 /\ InstVariant[SId] <= NumVariants[ShapeType[SId]]
);

% Symmetry breaking: instances of same shape type ordered by position
constraint forall(I in 1..S, J in 1..ShapeCounts[I]-1 where ShapeCounts[I] > 1) (
    let {
        int: SId1 = ShapeId[I, J],
        int: SId2 = ShapeId[I, J+1]
    } in
    Pos[SId1, 1] < Pos[SId2, 1] \/
    (Pos[SId1, 1] = Pos[SId2, 1] /\ Pos[SId1, 2] < Pos[SId2, 2])
);

% InstCells linked to Grid via element constraint
constraint forall(SId in 1..MaxShapeId, DI in 1..K, DJ in 1..K) (
    InstCells[SId, DI, DJ] = Grid[Idx[SId, DI, DJ, 1], Idx[SId, DI, DJ, 2]]
);

% Variant selection implies cells match SId
constraint forall(SId in 1..MaxShapeId) (
    let {
        int: SI = ShapeType[SId]
    } in
    forall(V in 1..NumVariants[SI]) (
        let {
            var bool: VarSel = (InstVariant[SId] = V)
        } in
        forall(DI in 1..K, DJ in 1..K where Variants[SI, V, DI, DJ] = 1) (
            VarSel -> InstCells[SId, DI, DJ] = SId
        )
    )
);

solve satisfy;

% Output
output [
    "Grid:\n"
] ++ [
    show(Grid[i, j]) ++ if j = N then "\n" else " " endif
    | i in 1..M, j in 1..N
] ++ [
    "\nPositions:\n"
] ++ [
    "Shape " ++ show(SId) ++ ": (" ++ show(Pos[SId, 1]) ++ ", " ++ show(Pos[SId, 2]) ++ ") variant " ++ show(InstVariant[SId]) ++ "\n"
    | SId in 1..MaxShapeId
];
