# Modeling a Tennis Match in Elm: What Changes in React or Svelte with TypeScript?

This application is deliberately small. It scores a best-of-three tennis match, starts a seven-point tiebreak at 6–6, displays the server, and lets either player win the next point. There is no database, authentication system, routing layer, or ambitious product roadmap.

That simplicity is useful because the project is not really an exercise in building a tennis product. It is an exercise in functional modeling: can the program describe the valid states of a tennis match clearly enough that many invalid states cannot be constructed?

Elm makes that question unusually visible. A comparable React or Svelte application written in TypeScript would likely be quicker to lay out and easier for most web developers to approach. It could also be designed very safely. The difference is not that Elm has types and TypeScript does not. The difference is how strongly the language, runtime, and application architecture encourage the types to remain the source of truth.

## The domain is a state machine

A naive tennis scorer might store regular-game points as two integers:

```ts
type GameScore = {
  playerOne: number;
  playerTwo: number;
};
```

That representation is convenient, but it admits states that do not mean anything in tennis:

```ts
{ playerOne: -3, playerTwo: 91 }
```

It also leaves display and transition code to rediscover the rules. Does `3–3` mean deuce? What does `4–3` mean? At what point should the integers reset?

The Elm application instead enumerates the meaningful regular-game states:

```elm
type PointScore
    = LoveLove
    | FifteenLove
    | LoveFifteen
    | FifteenAll
    | ThirtyLove
    | LoveThirty
    | ThirtyFifteen
    | FifteenThirty
    | ThirtyAll
    | FortyLove
    | LoveForty
    | FortyFifteen
    | FifteenForty
    | FortyThirty
    | ThirtyForty
    | Deuce
    | Advantage Player
```

The transition function pattern matches on the player who won the point and the current score:

```elm
regularGamePointWon : Player -> PointScore -> PointResult
regularGamePointWon player score =
    case ( player, score ) of
        ( PlayerOne, LoveLove ) ->
            PointScoreChanged FifteenLove

        ( PlayerTwo, LoveLove ) ->
            PointScoreChanged LoveFifteen

        -- Every other valid transition follows.
```

This is verbose. It is also explicit, total, and mechanically checked. If another `PointScore` variant is added, Elm reports every pattern match that has not accounted for it. A nonsensical score cannot appear unless someone deliberately adds that concept to the model.

The representation spends code to purchase guarantees, not to please a parser.

## TypeScript can model the same idea

TypeScript supports discriminated unions, so React or Svelte is not restricted to the naive integer representation:

```ts
type Player = "playerOne" | "playerTwo";

type PointScore =
  | { tag: "loveLove" }
  | { tag: "fifteenLove" }
  | { tag: "loveFifteen" }
  | { tag: "fifteenAll" }
  // ...
  | { tag: "deuce" }
  | { tag: "advantage"; player: Player };
```

An exhaustive transition function can use a `switch`, and a `never` check can make the compiler detect a missed case:

```ts
function assertNever(value: never): never {
  throw new Error(`Unexpected value: ${JSON.stringify(value)}`);
}
```

With strict compiler settings and disciplined code, TypeScript can capture much of the same domain design.

The tradeoff is that TypeScript’s guarantees are easier to bypass, sometimes intentionally and sometimes accidentally:

- Type assertions can claim that a value has a type without proving it.
- `any` disables checking across a boundary.
- JSON does not become valid merely because it receives a TypeScript annotation.
- Object mutation can invalidate assumptions held elsewhere.
- Exhaustiveness usually depends on a convention such as `assertNever`.

These are pragmatic features. They help TypeScript interoperate with JavaScript and let teams adopt stronger typing gradually. They also mean that “the type says this state is valid” can depend more heavily on project discipline.

Elm occupies a smaller world. There is no `any`, no general-purpose type assertion, and no way to mutate a record after another function receives it. External data must pass through a decoder before it can become an Elm value. The cost is more ceremony at boundaries and much less access to the JavaScript ecosystem. The benefit is that an Elm value is unusually trustworthy once it exists.

## Valid games, sets, and matches are different states

The application does not use one giant record with Boolean flags:

```ts
{
  isMatchComplete: boolean;
  isTiebreak: boolean;
  winner?: Player;
  currentGame?: Game;
}
```

Flags and optional fields admit contradictory combinations: a completed match with a current game, a tiebreak without a tiebreak score, or an unfinished match with a winner.

Elm uses distinct variants:

```elm
type Game
    = RegularGame RegularGameState
    | Tiebreak TiebreakState


type Match
    = InProgress MatchInProgress
    | Completed CompletedMatch
```

Rendering begins with a meaningful split:

```elm
case matchState of
    InProgress match ->
        viewInProgress events match

    Completed match ->
        viewCompleted events match
```

The completed branch cannot receive a playable current game because its type does not contain one.

TypeScript can express the same idea:

```ts
type Match =
  | { status: "inProgress"; match: MatchInProgress }
  | { status: "completed"; match: CompletedMatch };
```

Choosing React or Svelte does not require choosing a weak domain model. A TypeScript team can also make invalid states unrepresentable. Elm’s advantage is that this style feels like the path of least resistance throughout the language and its standard architecture.

## The update boundary is small

The top-level Elm application has two messages:

```elm
type Msg
    = PointWonBy Player
    | RestartMatch
```

Its update function delegates to a pure domain transition:

```elm
update : Msg -> Model -> Model
update msg model =
    case msg of
        PointWonBy player ->
            pointWon player model

        RestartMatch ->
            initialMatch
```

```elm
pointWon : Player -> Match -> Match
```

Given the same player and match, `pointWon` always returns the same next match. It does not update a component, mutate a store, touch the DOM, or depend on timing.

React can reach a similar design with `useReducer`:

```tsx
const [match, dispatch] = useReducer(matchReducer, initialMatch);

<button onClick={() => dispatch({ type: "pointWon", player: "playerOne" })}>
  Point for Player One
</button>
```

Svelte 5 can keep the match in reactive state and assign the result of the pure transition:

```svelte
<script lang="ts">
  let match = $state(initialMatch);
</script>

<button onclick={() => match = pointWon("playerOne", match)}>
  Point for Player One
</button>
```

Both can keep the domain independent of the framework. JavaScript component code, however, makes it easy to mix transition rules, UI state, effects, and rendering in the same file. Elm’s architecture continually pushes in the opposite direction: messages describe events, `update` produces state, and `view` produces HTML.

That constraint can feel excessive in a small form or animation. In a state machine, it is often helpful.

## The template is where React and Svelte are more comfortable

The scoreboard is the strongest argument for the JavaScript frameworks.

Elm constructs HTML with functions:

```elm
button
    [ class "point-button"
    , onClick (events.pointWon player)
    ]
    [ span [ class "button-label" ] [ text "Point for" ]
    , text name
    ]
```

JSX resembles HTML more closely:

```tsx
<button className="point-button" onClick={() => pointWon(player)}>
  <span className="button-label">Point for</span>
  {name}
</button>
```

Svelte is closer still:

```svelte
<button class="point-button" onclick={() => pointWon(player)}>
  <span class="button-label">Point for</span>
  {name}
</button>
```

For developers fluent in HTML, JSX and Svelte templates are usually faster to write and easier to scan. Browser examples can be pasted and adapted with less translation. Tooling for accessibility, component libraries, CSS systems, and visual testing is broader.

Elm’s HTML is ordinary function application. Attributes and child nodes are typed values, composition is function composition, and there is no separate template language. But consistency is not the same as readability. Deep markup accumulates brackets, commas, and indentation. A renderer such as `playerRow` can also accumulate many positional inputs, making its call sites difficult to interpret.

The view addresses that problem with state-specific adapters:

```elm
inProgressPlayerRow match PlayerOne
inProgressPlayerRow match PlayerTwo
```

Those functions normalize their inputs into a named record before calling the shared renderer. The result is clearer, but it is also work that a component template might make unnecessary.

## Would TypeScript reduce correctness?

Not automatically.

If a React or Svelte implementation used strict TypeScript settings, discriminated unions, a pure `pointWon` transition, exhaustive branching, immutable updates, runtime validation at external boundaries, and focused tests, its domain correctness could be very close to the Elm version.

The difference is sociotechnical rather than magical. TypeScript permits implementation styles ranging from carefully modeled functional code to loosely typed mutable component state. Elm permits a much narrower range. Elm therefore reduces the number of local decisions required to maintain the functional design.

In TypeScript, a team must repeatedly choose not to take shortcuts:

```ts
const match = response.json() as Match;
```

That assertion proves nothing about the response. A safer project would parse the value with a schema library or validator. Elm’s JSON decoder makes validation unavoidable.

On the other hand, this Elm model has limits. `SetScore` and `TiebreakScore` are aliases with the same record structure, so they are structurally compatible. Neither alias proves that its integers are non-negative or that a completed set has a legal score. Types improve the model, but they do not eliminate the need to choose where guarantees begin and end.

Correctness is not conferred by the framework. Elm makes a certain standard of correctness cheaper to sustain; TypeScript makes a wider range of engineering choices and integrations available.

## What the types do not prove

Even a carefully modeled Elm program needs tests.

The compiler proves that every `PointScore` passed to a total pattern match is handled, that completed and in-progress matches are distinguished, that functions receive declared shapes, and that state is not mutated behind a caller’s back.

It does not prove that the tennis rules were entered correctly. A transition from `FortyThirty` to `Deuce` after Player One wins would be well typed—and wrong. Nor does the compiler prove that tiebreak service alternates correctly.

The tests therefore concentrate on behavioral boundaries the types cannot establish:

- four points win a straightforward game,
- deuce and advantage require a two-point lead,
- 6–6 begins a tiebreak,
- a tiebreak requires a two-point margin,
- tiebreak service follows the one-point-then-pairs sequence, and
- two sets complete the match.

This is a useful division of labor. Types rule out broad categories of invalid programs; a small number of tests verify the domain decisions that remain.

A TypeScript version with the same model could use essentially the same tests. A version based on independent numeric and Boolean fields would need more tests because more invalid combinations would be constructible.

## Effects and runtime behavior

This application uses `Browser.sandbox`, so it has no commands or subscriptions. In a larger Elm application, effects are represented as data returned from `update`, and the runtime performs them. That preserves a pure core but introduces an explicit layer for HTTP, time, randomness, browser events, and JavaScript interop.

React and Svelte integrate effects more directly into component lifecycles. That is convenient, especially when using browser libraries. It also creates more opportunities for behavior to depend on render timing, stale closures, dependency arrays, effect scheduling, or code distributed among runes and component callbacks.

Elm trades directness for control. React and Svelte trade some control for flexibility and ecosystem access.

For this scorer, the difference is barely visible because scoring is pure. For an application with live feeds, persistence, analytics, authentication, and animation, the tradeoff would become much more significant.

## The deliberate `contenteditable` exception

The player names use unmanaged browser `contenteditable` behavior. Editing the visible text does not update the Elm model. React developers might call this an uncontrolled DOM value; Svelte could bind it to state more directly. Elm could model name-editing messages, but that would add code unrelated to the central exercise.

This exception is instructive: architectural purity has a cost, and not every ephemeral interaction deserves a complete domain model. The important thing is that the exception is deliberate and isolated. If edited names later needed to survive rerenders, restarts, or persistence, the current approach would no longer be sufficient.

## Developer experience and ecosystem

Elm offers:

- helpful compiler errors,
- enforced immutability and pure functions,
- exhaustive custom-type handling,
- a consistent application architecture, and
- confidence when refactoring modeled state.

It also has substantial costs:

- a much smaller package and hiring ecosystem,
- interop boundaries around JavaScript libraries,
- fewer current UI kits and integrations,
- function-based HTML that some readers find noisy, and
- less flexibility when an application wants to escape the standard architecture.

React with TypeScript offers the largest component ecosystem, familiar JSX, many rendering strategies, gradual adoption of type-driven techniques, and direct access to JavaScript libraries. Its cost is a large decision surface: state libraries, effect patterns, data-fetching tools, schema systems, and conventions for preserving type safety. React allows a clean architecture but does not provide one complete architecture by default.

Svelte with TypeScript offers templates close to HTML, concise reactivity, little component boilerplate, and the JavaScript ecosystem. Its convenience can make transitions feel less formal. A team that wants this Elm-style design must intentionally keep the domain pure and resist spreading rules among reactive assignments and components.

## Which implementation would be shorter?

A React or Svelte MVP would probably be shorter in its view layer. Svelte would likely produce the most immediately readable scoreboard template. React would make it easy to use familiar components and UI libraries.

The domain layer might not be shorter if it preserved the same guarantees. Discriminated unions, exhaustive reducers, immutable updates, and runtime parsing all require code. TypeScript often appears dramatically shorter when the comparison silently weakens the model—for example, replacing `PointScore` with two numbers and several conditions.

That may still be a rational trade. Not every project needs the strongest representation. The important comparison is not line count alone but what each line promises.

## Adding features changes the comparison

The current rules are intentionally fixed: best of three sets, a tiebreak at 6–6, and ordinary advantage scoring. Real feature work would put the model under more pressure.

Suppose the application later supports best-of-five matches, no-ad games, ten-point match tiebreaks, or tournaments whose final sets use different rules. The current constants and transitions would no longer be enough. The domain would need an explicit rules value:

```elm
type alias MatchRules =
    { setsToWin : Int
    , regularGame : RegularGameRule
    , finalSet : FinalSetRule
    }
```

Functions such as `pointWon`, `setIsWonBy`, and `tiebreakIsWonBy` would then receive the appropriate rule instead of embedding one format. Elm’s compiler would help locate every place affected by the new distinctions. That guidance is valuable, but the change could touch many signatures. A strongly modeled design makes new concepts explicit; it does not make them free.

TypeScript discriminated unions can provide similar compiler guidance. The practical difference appears if the original implementation used scattered numbers and conditions. Changing a central `MatchRules` value is manageable; finding every component that independently assumes “first to seven” is much harder. Future flexibility depends at least as much on where rules live as on which framework renders the scoreboard.

Other features stress different boundaries:

- Undo and point history favor representing events explicitly, perhaps replaying a list of `PointWonBy Player` values rather than saving mutable snapshots.
- Persistence requires encoding and decoding the model. Elm forces that boundary to be explicit; TypeScript normally needs a runtime schema in addition to its static types.
- Live scoring introduces commands, subscriptions, reconnection state, and possibly conflicting updates. Elm keeps those effects outside the pure transition, while React and Svelte offer more library choices for synchronizing remote state.
- Editable player names should move out of unmanaged `contenteditable` behavior and into modeled state once names must survive rerenders or persistence.
- Rich animation may be easier to integrate through the React or Svelte ecosystem, while Elm may require more custom work or JavaScript interop.

The model should therefore evolve in response to concrete features, not attempt to predict every future tournament format. The useful foundation is the separation already present: tennis rules are pure domain transitions, application messages describe intent, and the view only renders state. That separation leaves room to add capabilities without making the initial MVP carry all of their complexity.

## When each approach fits

Elm is especially compelling when intricate client state dominates, invalid combinations are a major risk, JavaScript integrations are modest, refactoring confidence matters, and the team values a constrained architecture. Scoring systems, workflow editors, form engines, rules-driven configurators, and educational tools can fit that profile.

React or Svelte with TypeScript is usually more pragmatic when the project relies heavily on JavaScript libraries, full-stack framework features are central, developers need HTML-like templates, staffing and ecosystem maturity dominate, or the application benefits from choosing among multiple architectural styles.

## Conclusion

This tennis scorer is not evidence that Elm can model states and TypeScript cannot. Both can. It demonstrates a subtler difference.

Elm turns functional, type-driven state modeling into the default terrain. The compiler, immutable values, custom types, exhaustive pattern matching, and Elm Architecture all reinforce the same direction. That makes the scoreboard markup somewhat more cumbersome and narrows the ecosystem, but it gives the domain model unusual authority.

React and Svelte with TypeScript offer friendlier templates, broader tooling, and more freedom. A careful implementation can retain nearly all of the domain strengths shown here. The price is that correctness depends more on conventions, compiler configuration, boundary validation, and continued team discipline.

The lesson is not “Elm good, TypeScript bad.” It is that language and framework design change the cost of maintaining an idea. Elm makes it expensive to step outside the modeled state machine. React and Svelte make it easy to choose how much of that machine to model in the first place.

That difference is the experiment.
