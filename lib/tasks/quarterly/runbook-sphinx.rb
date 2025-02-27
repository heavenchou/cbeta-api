require 'runbook'

module RunbookSectionSphinx
  def define_section_sphinx(config)
    step_sphinx_x2t = define_step_sphinx_x2t(config)
    step_sphinx_t2x = define_step_shpinx_t2x(config)
    step_sphinx_create_folder = define_step_sphinx_create_folder(config)
    step_sphinx_config = define_step_sphinx_config(config)
    step_sphinx_index = define_step_sphinx_index(config)
    step_sphinx_vars = define_step_sphinx_vars(config)

    Runbook.section "Sphinx" do
      add step_sphinx_create_folder
      add step_sphinx_config
      add step_sphinx_x2t
      add step_sphinx_t2x
      add step_sphinx_index
      add step_sphinx_vars
    end # Runbook.section
  end # def define_section_sphinx(config)

  def define_step_sphinx_config(config)
    Runbook.step 'sphinx configuration' do
      ruby_command do |rb_cmd, metadata, run|
        v = config[:v]
        base = Rails.configuration.x.sphinx_base

        %w[cbdata notes titles].each do |index|
          fn = Rails.root.join("lib/tasks/quarterly/sphinx-template-#{index}.conf")
          template = File.read(fn)
          s = template % { v: v }
          dest = File.join(base, "#{v}-#{index}.conf")
          puts "write #{dest}"
          File.write(dest, s)
        end

        Dir.chdir(base) do
          `ruby merge.rb`
        end
      end
      note "可以手動清除 #{Rails.configuration.x.sphinx_base} 資料夾下的舊資料"
    end
  end

  def define_step_sphinx_create_folder(config)
    Runbook.step 'sphin 建資料夾' do
      ruby_command do |rb_cmd, metadata, run|
        v = config[:v]
        Dir.chdir('/var/lib/sphinx') do
          ["", "-notes", "-titles"].each do |s|
            cmd = "sudo mkdir data#{v}#{s}"
            puts cmd
            system cmd
            system "sudo chown -R sphinx:sphinx data#{v}#{s}"
          end
        end
      end
    end
  end

  def define_step_sphinx_index(config)
    if Rails.env.development?
      Runbook.step 'sphinx index' do
        ruby_command do |rb_cmd, metadata, run|
          Dir.chdir('/Users/ray/Documents/Projects/CBETAOnline/sphinx') do
            system "indexer --rotate cbeta"
            system "indexer --rotate notes"
            system "indexer --rotate titles"
          end
        end
      end
    else
      Runbook.step 'sphin index' do
        ruby_command do |rb_cmd, metadata, run|
          %w[cbeta notes titles].each do |s|
            cmd = "sudo indexer --config /etc/sphinx/sphinx.conf --rotate #{s}#{config[:v]}"
            puts cmd
            system cmd
          end

          # 不改權限會有問題 (不知道如何設定 indexer 新建檔案的預設 owner)
          cmd = "sudo chown -R sphinx:sphinx /var/lib/sphinx"
          puts cmd
          system cmd
          
          cmd = 'sudo service sphinx restart'
          puts cmd
          system cmd
        end

        note '可手動清除舊版 Index: /var/lib/sphinx'
        note '注意 /var/lib/sphinx/data 不能刪。'
      end
    end
  end

  def define_step_shpinx_t2x(config)
    Runbook.step '轉出 sphinx 所需的 xml' do
      confirm <<~MSG
      需要部類、時間資訊，要執行過：
        rake import:category
        rake import:time
      MSG
      command 'rake sphinx:t2x'
      command 'rake sphinx:notes'
      command 'rake sphinx:titles'
    end
  end

  def define_step_sphinx_vars(config)
    Runbook.step '匯入 異體字 (rake import:vars)' do
      confirm '這要在 Sphinx Index 建好之後才能執行'
      note '資料來源是 https://github.com/DILA-edu/cbeta-metadata/blob/master/variants/variants.json'
      command 'rake import:vars'
    end
  end

  def define_step_sphinx_x2t(config)
    Runbook.step '先把 XML P5a 轉為 text' do
      confirm '如果欄位有變更，要修改： /etc/sphinxsearch/sphinx.conf'
      command 'rake sphinx:x2t'
    end
  end

  def exec(cmd)
    puts cmd
    system cmd
  end
end # end of module