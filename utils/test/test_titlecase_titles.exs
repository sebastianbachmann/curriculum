defmodule MyTitleCaseTest do
  use ExUnit.Case
  alias Livebook.LiveMarkdown.MarkdownHelpers

  # Started from here: https://stackoverflow.com/a/40559914

  @one_word_title_titlecase_regex ~r/^[A-Z].*$/
  @first_letter_cap_regex ~r/^[A-Z]/
  @articles_conjunctions_prepositions "(a|an|and|but|for|in|of|on|or|the|with)"
  @other_titlecase_ignored "(vs)"

  test "all titles should be in title case" do
    exercises = fetch_livebooks("../exercises/")
    reading = fetch_livebooks("../reading/")

    (exercises ++ reading)
    |> Enum.each(fn f ->
      IO.puts("Checking #{f}")

      file_contents = File.read!(f)
      {_, ast, _} = MarkdownHelpers.markdown_to_block_ast(file_contents)

      # get only headers in file
      header_list =
        Enum.filter(ast, fn
          {tag, _, _, _} when is_binary(tag) -> String.match?(tag, ~r/h[1-6]/)
          _ -> false
        end)

      # check each header for titlcase
      Enum.each(header_list, fn {tag, _, [content], _} ->
        # IO.puts("#{f} - #{content}")

        word_list = String.split(content)

        # if header is only one word, check that it's capitalized
        if length(word_list) == 1 do
          single_word = word_list |> filter_headline |> List.first()

          if is_binary(single_word) && !String.starts_with?(single_word, ":") do
            assert String.match?(single_word, @one_word_title_titlecase_regex),
                   "[#{f}] expected: \"#{single_word}\" to be capitalized"
          end
        else
          first_word = Enum.at(word_list, 0)

          # check if the first word in the title is an article, conjunction or prepositions
          # and if so, then it must capitalized
          if String.match?(first_word, ~r/^#{@articles_conjunctions_prepositions}/) do
            assert String.match?(first_word, @first_letter_cap_regex),
                   "[#{f}] expected:\n\t\"#{first_word}\" in\n\t\"#{content}\" to be capitalized"
          end

          is_line_titlecase =
            word_list
            # filter out punctuations , `#`'s, articles, conjunctions, prepositions, numbers
            |> filter_headline
            # check each word starts with a capital letter
            |> Enum.all?(fn word -> String.match?(word, ~r/^[A-Z]/) end)

          assert is_line_titlecase, "[#{f}] expected \"#{content}\" to be titlecase"
        end
      end)
    end)
  end

  defp fetch_livebooks(path) do
    File.ls!(path)
    |> Stream.filter(&String.ends_with?(&1, ".livemd"))
    |> Enum.map(&(path <> &1))
  end

  def filter_headline(word_list) do
    Enum.filter(
      word_list,
      &(!String.match?(
          &1,
          ~r/.*\/[0-9]$|[!"#$%&'()*+,-.:;<=>?@[\]^_`{|}~]|\b#{@articles_conjunctions_prepositions}\b|\b#{@other_titlecase_ignored}\b|#+|\b[0-9]+\b/
        ))
    )
  end
end
