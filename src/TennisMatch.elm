module TennisMatch exposing
    ( CompletedMatch
    , CompletedSet(..)
    , Game(..)
    , Match(..)
    , MatchInProgress
    , Player(..)
    , PlayerNames
    , PointScore(..)
    , RegularGameState
    , SetInProgress
    , SetScore
    , TiebreakScore
    , TiebreakState
    , initialMatch
    , otherPlayer
    , pointWon
    , tiebreakServer
    )

{-| Domain sketch for a best-of-three match.

Each set plays a seven-point tiebreak at 6-6. Player One serves first in the
match.

-}

-- PARTICIPANTS


type Player
    = PlayerOne
    | PlayerTwo


type alias PlayerNames =
    { playerOne : String
    , playerTwo : String
    }


otherPlayer : Player -> Player
otherPlayer player =
    case player of
        PlayerOne ->
            PlayerTwo

        PlayerTwo ->
            PlayerOne



-- GAME


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


type PointResult
    = PointScoreChanged PointScore
    | RegularGameWonBy Player


type Game
    = RegularGame RegularGameState
    | Tiebreak TiebreakState


type GameResult
    = GameContinues Game
    | RegularGameWon RegularGameWin
    | TiebreakWon TiebreakWin


type alias RegularGameWin =
    { winner : Player
    , server : Player
    }


type alias TiebreakWin =
    { winner : Player
    , score : TiebreakScore
    , firstServer : Player
    }


type alias RegularGameState =
    { score : PointScore
    , server : Player
    }


type alias TiebreakScore =
    { playerOne : Int
    , playerTwo : Int
    }


type alias TiebreakState =
    { score : TiebreakScore
    , firstServer : Player
    }


initialRegularGame : Player -> Game
initialRegularGame server =
    RegularGame
        { score = LoveLove
        , server = server
        }


initialTiebreak : Player -> Game
initialTiebreak firstServer =
    Tiebreak
        { score = { playerOne = 0, playerTwo = 0 }
        , firstServer = firstServer
        }


gamePointWon : Player -> Game -> GameResult
gamePointWon pointWinner game =
    case game of
        RegularGame state ->
            case regularGamePointWon pointWinner state.score of
                PointScoreChanged score ->
                    GameContinues (RegularGame { state | score = score })

                RegularGameWonBy winner ->
                    RegularGameWon
                        { winner = winner
                        , server = state.server
                        }

        Tiebreak state ->
            let
                score =
                    incrementTiebreakScore pointWinner state.score
            in
            if tiebreakIsWonBy pointWinner score then
                TiebreakWon
                    { winner = pointWinner
                    , score = score
                    , firstServer = state.firstServer
                    }

            else
                GameContinues (Tiebreak { state | score = score })


regularGamePointWon : Player -> PointScore -> PointResult
regularGamePointWon pointWinner score =
    case ( pointWinner, score ) of
        ( PlayerOne, LoveLove ) ->
            PointScoreChanged FifteenLove

        ( PlayerTwo, LoveLove ) ->
            PointScoreChanged LoveFifteen

        ( PlayerOne, FifteenLove ) ->
            PointScoreChanged ThirtyLove

        ( PlayerTwo, FifteenLove ) ->
            PointScoreChanged FifteenAll

        ( PlayerOne, LoveFifteen ) ->
            PointScoreChanged FifteenAll

        ( PlayerTwo, LoveFifteen ) ->
            PointScoreChanged LoveThirty

        ( PlayerOne, FifteenAll ) ->
            PointScoreChanged ThirtyFifteen

        ( PlayerTwo, FifteenAll ) ->
            PointScoreChanged FifteenThirty

        ( PlayerOne, ThirtyLove ) ->
            PointScoreChanged FortyLove

        ( PlayerTwo, ThirtyLove ) ->
            PointScoreChanged ThirtyFifteen

        ( PlayerOne, LoveThirty ) ->
            PointScoreChanged FifteenThirty

        ( PlayerTwo, LoveThirty ) ->
            PointScoreChanged LoveForty

        ( PlayerOne, ThirtyFifteen ) ->
            PointScoreChanged FortyFifteen

        ( PlayerTwo, ThirtyFifteen ) ->
            PointScoreChanged ThirtyAll

        ( PlayerOne, FifteenThirty ) ->
            PointScoreChanged ThirtyAll

        ( PlayerTwo, FifteenThirty ) ->
            PointScoreChanged FifteenForty

        ( PlayerOne, ThirtyAll ) ->
            PointScoreChanged FortyThirty

        ( PlayerTwo, ThirtyAll ) ->
            PointScoreChanged ThirtyForty

        ( PlayerOne, FortyLove ) ->
            RegularGameWonBy PlayerOne

        ( PlayerTwo, FortyLove ) ->
            PointScoreChanged FortyFifteen

        ( PlayerOne, LoveForty ) ->
            PointScoreChanged FifteenForty

        ( PlayerTwo, LoveForty ) ->
            RegularGameWonBy PlayerTwo

        ( PlayerOne, FortyFifteen ) ->
            RegularGameWonBy PlayerOne

        ( PlayerTwo, FortyFifteen ) ->
            PointScoreChanged FortyThirty

        ( PlayerOne, FifteenForty ) ->
            PointScoreChanged ThirtyForty

        ( PlayerTwo, FifteenForty ) ->
            RegularGameWonBy PlayerTwo

        ( PlayerOne, FortyThirty ) ->
            RegularGameWonBy PlayerOne

        ( PlayerTwo, FortyThirty ) ->
            PointScoreChanged Deuce

        ( PlayerOne, ThirtyForty ) ->
            PointScoreChanged Deuce

        ( PlayerTwo, ThirtyForty ) ->
            RegularGameWonBy PlayerTwo

        ( PlayerOne, Deuce ) ->
            PointScoreChanged (Advantage PlayerOne)

        ( PlayerTwo, Deuce ) ->
            PointScoreChanged (Advantage PlayerTwo)

        ( PlayerOne, Advantage PlayerOne ) ->
            RegularGameWonBy PlayerOne

        ( PlayerTwo, Advantage PlayerOne ) ->
            PointScoreChanged Deuce

        ( PlayerOne, Advantage PlayerTwo ) ->
            PointScoreChanged Deuce

        ( PlayerTwo, Advantage PlayerTwo ) ->
            RegularGameWonBy PlayerTwo


incrementTiebreakScore : Player -> TiebreakScore -> TiebreakScore
incrementTiebreakScore pointWinner score =
    case pointWinner of
        PlayerOne ->
            { score | playerOne = score.playerOne + 1 }

        PlayerTwo ->
            { score | playerTwo = score.playerTwo + 1 }


tiebreakIsWonBy : Player -> TiebreakScore -> Bool
tiebreakIsWonBy pointWinner score =
    let
        ( winnerPoints, loserPoints ) =
            case pointWinner of
                PlayerOne ->
                    ( score.playerOne, score.playerTwo )

                PlayerTwo ->
                    ( score.playerTwo, score.playerOne )
    in
    winnerPoints >= 7 && winnerPoints - loserPoints >= 2


tiebreakServer : TiebreakState -> Player
tiebreakServer state =
    let
        pointsPlayed =
            state.score.playerOne + state.score.playerTwo
    in
    case modBy 4 pointsPlayed of
        1 ->
            otherPlayer state.firstServer

        2 ->
            otherPlayer state.firstServer

        _ ->
            state.firstServer


-- SET


type alias SetScore =
    { playerOne : Int
    , playerTwo : Int
    }


type alias SetInProgress =
    { games : SetScore
    , game : Game
    }


type CompletedSet
    = RegularSet SetScore
    | TiebreakSet SetScore TiebreakScore


initialSet : Player -> SetInProgress
initialSet server =
    { games =
        { playerOne = 0
        , playerTwo = 0
        }
    , game = initialRegularGame server
    }


incrementSetScore : Player -> SetScore -> SetScore
incrementSetScore gameWinner score =
    case gameWinner of
        PlayerOne ->
            { score | playerOne = score.playerOne + 1 }

        PlayerTwo ->
            { score | playerTwo = score.playerTwo + 1 }


setIsWonBy : Player -> SetScore -> Bool
setIsWonBy gameWinner score =
    let
        ( winnerGames, loserGames ) =
            case gameWinner of
                PlayerOne ->
                    ( score.playerOne, score.playerTwo )

                PlayerTwo ->
                    ( score.playerTwo, score.playerOne )
    in
    winnerGames >= 6 && winnerGames - loserGames >= 2


nextGame : SetScore -> Player -> Game
nextGame setScore server =
    if setScore.playerOne == 6 && setScore.playerTwo == 6 then
        initialTiebreak server

    else
        initialRegularGame server


completedSetWinner : CompletedSet -> Player
completedSetWinner completedSet =
    let
        score =
            case completedSet of
                RegularSet setScore ->
                    setScore

                TiebreakSet setScore _ ->
                    setScore
    in
    if score.playerOne > score.playerTwo then
        PlayerOne

    else
        PlayerTwo


-- MATCH


type Match
    = InProgress MatchInProgress
    | Completed CompletedMatch


type alias MatchInProgress =
    { players : PlayerNames
    , completedSets : List CompletedSet
    , currentSet : SetInProgress
    }


type alias CompletedMatch =
    { players : PlayerNames
    , sets : List CompletedSet
    }


initialMatch : Match
initialMatch =
    InProgress
        { players =
            { playerOne = "Player One"
            , playerTwo = "Player Two"
            }
        , completedSets = []
        , currentSet = initialSet PlayerOne
        }


pointWon : Player -> Match -> Match
pointWon pointWinner matchState =
    case matchState of
        InProgress match ->
            updateInProgress pointWinner match

        Completed _ ->
            matchState


updateInProgress : Player -> MatchInProgress -> Match
updateInProgress pointWinner match =
    case gamePointWon pointWinner match.currentSet.game of
        GameContinues game ->
            InProgress (replaceCurrentGame game match)

        RegularGameWon result ->
            finishRegularGame result match

        TiebreakWon result ->
            finishTiebreak result match


replaceCurrentGame : Game -> MatchInProgress -> MatchInProgress
replaceCurrentGame game match =
    let
        currentSet =
            match.currentSet
    in
    { match | currentSet = { currentSet | game = game } }


finishRegularGame : RegularGameWin -> MatchInProgress -> Match
finishRegularGame result match =
    let
        updatedGames =
            incrementSetScore result.winner match.currentSet.games

        nextServer =
            otherPlayer result.server
    in
    if setIsWonBy result.winner updatedGames then
        completeSet result.winner (RegularSet updatedGames) nextServer match

    else
        InProgress
            { match
                | currentSet =
                    { games = updatedGames
                    , game = nextGame updatedGames nextServer
                    }
            }


finishTiebreak : TiebreakWin -> MatchInProgress -> Match
finishTiebreak result match =
    let
        finalSetScore =
            incrementSetScore result.winner match.currentSet.games
    in
    completeSet
        result.winner
        (TiebreakSet finalSetScore result.score)
        (otherPlayer result.firstServer)
        match


completeSet : Player -> CompletedSet -> Player -> MatchInProgress -> Match
completeSet winner completedSet nextServer match =
    let
        updatedMatch =
            { match
                | completedSets =
                    match.completedSets ++ [ completedSet ]
            }
    in
    if matchIsWonBy winner updatedMatch then
        Completed
            { players = updatedMatch.players
            , sets = updatedMatch.completedSets
            }

    else
        InProgress
            { updatedMatch
                | currentSet = initialSet nextServer
            }


matchIsWonBy : Player -> MatchInProgress -> Bool
matchIsWonBy player match =
    match.completedSets
        |> List.filter (completedSetWinner >> (==) player)
        |> List.length
        |> (==) 2
