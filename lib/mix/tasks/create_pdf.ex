defmodule Mix.Tasks.CreatePdf do
  use Mix.Task

  @shortdoc "Mohan"
  def run(_) do
    CreatePdf.course_report()
  end
end
