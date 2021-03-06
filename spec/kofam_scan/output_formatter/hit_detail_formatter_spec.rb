require_relative 'shared_contexts'

RSpec.describe KofamScan::OutputFormatter::HitDetailFormatter do
  def output_array
    output_lines = output.split(/\n/).grep_v(/^#/)
    output_lines.map do |line|
      mark = line.slice!(0, 1)
      [mark, *line.split(nil, 6)]
    end
  end

  describe '#format' do
    context 'the simplest context' do
      include_context 'one hit for one gene'
      let(:expected_output) { <<~RESULT }
        # gene name           KO     thrshld  score   E-value KO definition
        #-------------------- ------ ------- ------ --------- ---------------------
          gene1               K00001   99.52   50.1    0.0009 alcohol dehydrogenase [EC:1.1.1.1]
        * gene2               K00002  150.00  180.0     5e-05 alcohol dehydrogenase (NADP+) [EC:1.1.1.2]
        * gene4               K00003  200.00  200.0   1.2e-10 homoserine dehydrogenase [EC:1.1.1.3]
      RESULT

      it 'gives the right output' do
        expect(output).to eq expected_output
      end
    end

    context 'multiple hits for one gene' do
      include_context description

      it 'includes all the hits for the gene' do
        gene1_lines = output.split(/\n/).grep(/gene1/)
        expect(gene1_lines.size).to eq 3
      end

      it 'gives result in the order of gene name and score' do
        gene_ko_pair = output_array.map { |line| line.values_at(1, 2) }
        expect(gene_ko_pair).to match [
          %w[gene1 K00002],
          %w[gene1 K00001],
          %w[gene1 K00003],
          %w[gene4 K00002]
        ]
      end
    end

    context 'multiple hits for one KO' do
      include_context description

      it 'includes all the hits for the KO' do
        k00001_lines = output.split(/\n/).grep(/K00001/)
        expect(k00001_lines.size).to eq 2
      end
    end

    context 'with a long gene name' do
      include_context description

      it "does not truncate the gene name" do
        gene_name_out = output_array.first[1]
        expect(gene_name_out).to eq long_name
      end

      it 'outputs the header with appropreate margin' do
        header1 = output.split(/\n/).first
        gene_name_column = header1.slice(/gene name\s+/).chop

        expect(gene_name_column.size).to eq name_length
      end

      it 'outputs the header delimiter with appropreate margin' do
        header2 = output.split(/\n/)[1]
        first_column = header2.split.first

        expect(first_column).to eq('#-' + '-' * name_length)
      end
    end

    context 'when report_unannotated is true' do
      include_examples description, <<~RESULT
        # gene name           KO     thrshld  score   E-value KO definition
        #-------------------- ------ ------- ------ --------- ---------------------
          gene1               K00001   99.52   50.1    0.0009 alcohol dehydrogenase [EC:1.1.1.1]
        * gene2               K00002  150.00  180.0     5e-05 alcohol dehydrogenase (NADP+) [EC:1.1.1.2]
          gene3               -            -      -         - -
        * gene4               K00003  200.00  200.0   1.2e-10 homoserine dehydrogenase [EC:1.1.1.3]
          gene5               -            -      -         - -
      RESULT
    end

    context 'when a threshold is nil' do
      include_context 'basic context'

      let(:ko_without_threshold) do
        KofamScan::KO.new("K00001", nil, nil, nil, nil, 100, 100, 200, 100,
                          10, 0.5, "alcohol dehydrogenase [EC:1.1.1.1]")
      end

      before do
        result << KofamScan::Result::Hit.new("gene1", ko_without_threshold, 1000, 0.0009)
      end

      it 'gives the output with threshold "-"' do
        expect(output_array[0][3]).to eq '-'
      end

      it 'does not mark the hit with asterisk' do
        expect(output_array[0][0]).to eq ' '
      end
    end
  end
end
