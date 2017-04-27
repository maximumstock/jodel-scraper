# defmodule JodelScraper.Evaluations.Frequency.Setup do
#
#
#   alias JodelScraper.Evaluations.Frequency.{Scraper, Processor}
#
#   require Logger
#
#   @intervals [30, 60, 120, 240, 600]
#
#   def start do
#
#     @intervals
#     |> Enum.map(fn interval ->
#         {:ok, producer} = Producer.start_test()
#         {:ok, consumer} = Consumer.start_link()
#         GenStage.sync_subscribe(consumer, to: producer)
#         {consumer, interval}
#     end)
#     |> Enum.each(fn {consumer, interval} ->
#       Process.send_after(self(), {:tick, consumer, interval}, interval*1000)
#     end)
#
#     loop()
#
#   end
#
#   def loop do
#     receive do
#       {:tick, consumer, interval} = msg ->
#         Consumer.ask(consumer)
#         Process.send_after(self(), msg, interval*1000)
#         loop()
#     end
#   end
#
# end
