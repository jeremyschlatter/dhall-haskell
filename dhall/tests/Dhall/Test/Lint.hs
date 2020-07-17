{-# LANGUAGE OverloadedStrings #-}

module Dhall.Test.Lint where

import Data.Monoid  (mempty, (<>))
import Data.Text    (Text)
import Dhall.Parser (Header (..))
import Prelude      hiding (FilePath)
import Test.Tasty   (TestTree)
import Turtle       (FilePath)

import qualified Data.Text                             as Text
import qualified Data.Text.IO                          as Text.IO
import qualified Data.Text.Prettyprint.Doc             as Doc
import qualified Data.Text.Prettyprint.Doc.Render.Text as Doc.Render.Text
import qualified Dhall.Core                            as Core
import qualified Dhall.Lint                            as Lint
import qualified Dhall.Parser                          as Parser
import qualified Dhall.Pretty                          as Pretty
import qualified Dhall.Test.Util                       as Test.Util
import qualified Test.Tasty                            as Tasty
import qualified Test.Tasty.HUnit                      as Tasty.HUnit
import qualified Turtle

lintDirectory :: FilePath
lintDirectory = "./tests/lint"

getTests :: IO TestTree
getTests = do
    lintTests <- Test.Util.discover (Turtle.chars <* "A.dhall") lintTest (Turtle.lstree lintDirectory)

    let testTree = Tasty.testGroup "lint tests" [ lintTests ]

    return testTree

format :: Header -> Core.Expr Parser.Src Core.Import -> Text
format (Header header) expr =
    let doc =  Doc.pretty header
            <> Pretty.prettyCharacterSet Pretty.Unicode expr
            <> "\n"

        docStream = Pretty.layout doc
    in
        Doc.Render.Text.renderStrict docStream

lintTest :: Text -> TestTree
lintTest prefix =
    Tasty.HUnit.testCase (Text.unpack prefix) $ do
        let inputFile  = Text.unpack (prefix <> "A.dhall")
        let outputFile = Text.unpack (prefix <> "B.dhall")

        inputText <- Text.IO.readFile inputFile

        (header, parsedInput) <- Core.throws (Parser.exprAndHeaderFromText mempty inputText)

        let actualExpression = Lint.lint parsedInput

        let actualText = format header actualExpression

        expectedText <- Text.IO.readFile outputFile

        let message = "The linted expression did not match the expected output"

        Tasty.HUnit.assertEqual message expectedText actualText
