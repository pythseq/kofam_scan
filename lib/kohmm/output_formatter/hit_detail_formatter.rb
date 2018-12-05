module KOHMM
  class OutputFormatter
    class HitDetailFormatter < OutputFormatter
      COLUMN_WIDTH = {
        gene_name:     19,
        ko:            6,
        score:         6,
        e_value:       9,
        ko_definition: 21
      }.freeze
      private_constant :COLUMN_WIDTH

      def initialize
        @report_unannotated = false
      end

      def format(result, output)
        output << header
        result.query_list.each do |query|
          hits = result.for_gene(query)
          if hits.empty?
            output << format_empty_hit(query) << "\n" if @report_unannotated
            next
          end

          hits.sort_by(&:score).reverse_each do |hit|
            output << format_hit(hit) << "\n"
          end
        end
      end

      private

      def header
        "#{header_first_line}\n#{header_delimiter_line}\n"
      end

      def header_first_line
        template = "# %-#{COLUMN_WIDTH[:gene_name]}s %-#{COLUMN_WIDTH[:ko]}s " \
                   "%#{COLUMN_WIDTH[:score]}s %#{COLUMN_WIDTH[:e_value]}s %-s"
        template % %w[gene\ name KO score E-value KO\ definition]
      end

      def header_delimiter_line
        "#-" +
          COLUMN_WIDTH.values_at(:gene_name, :ko, :score, :e_value, :ko_definition)
                      .map { |i| '-' * i }.join(' ')
      end

      def format_hit(hit)
        template = "%1s %-#{COLUMN_WIDTH[:gene_name]}s " \
                   "%-#{COLUMN_WIDTH[:ko]}s " \
                   "%#{COLUMN_WIDTH[:score]}.1f " \
                   "%#{COLUMN_WIDTH[:e_value]}.2g %s"
        mark = hit.above_threshold? ? '*' : ' '
        truncated_gene_name = hit.gene_name[0, COLUMN_WIDTH[:gene_name]]
        template % [mark, truncated_gene_name, hit.ko.name, hit.score, hit.e_value, hit.ko.definition]
      end

      def format_empty_hit(query)
        "  %-#{COLUMN_WIDTH[:gene_name]}s -#{' ' * (COLUMN_WIDTH[:ko] - 1)}" \
        "#{' ' * COLUMN_WIDTH[:score]}-#{' ' * COLUMN_WIDTH[:e_value]}- -" %
          query[0, COLUMN_WIDTH[:gene_name]]
      end
    end
  end
end
