defmodule CreatePdf do
  @moduledoc """
  Documentation for CreatePdf.
  """
  def course_report do
    generate_pdf()
  end

  @spec generate_pdf :: :ok | {:error, atom}
  def generate_pdf do
    list_data = File.read!(get_file_path())
    {_, list} = JSON.decode(list_data)
    raw_text = String.split(list["document"]["tail"]["raw_text"], "\n")

    content_text =
      Enum.reduce(raw_text, "", fn sd, acc3 ->
        acc3 <> "#{sd}<br> <br>"
      end)

    category_list = list["document"]["body"]["list"]
    body = body_section(category_list)
    html = render_html(list, body, content_text)
    img = image_path()
    File.write!("./header.html", header_content(img))
    File.write!("./footer.html", footer_content(list))

    {:ok, filename} =
      PdfGenerator.generate(html,
        page_size: "A4",
        shell_params: [
          "--header-html",
          "header.html",
          "--footer-html",
          "footer.html"
        ]
      )

    File.rename(filename, "./course.pdf")
  end

  @spec body_section(any) :: any
  @doc """
  body section and comments, schedule
  """
  def body_section(category_list) do
    Enum.reduce(category_list, "", fn category, acc ->
      items =
        Enum.reduce(category["items"], "", fn item, acc1 ->
          comments = item["comment_label"]
          temp = if !is_nil(comments), do: comments <> ": " <> item["comment_value"], else: nil
          schedule = if item["schedule"] != nil, do: item["schedule"], else: []

          test_data =
            Enum.reduce(schedule, "", fn z, acc2 ->
              schedule_content(acc2, z)
            end)

          items_content(acc1, item, temp, test_data)
        end)

      categories_content(acc, category, items)
    end)
  end

  def items_content(acc1, item, temp, test_data) do
    acc1 =
      if not is_nil(item["dates"]) do
        acc1 <> "
        <div class='date_style'>#{item["dates"]}</div>"
      else
        acc1
      end

    acc1 =
      if not is_nil(item["course_name"]) do
        acc1 <> "
        <div class='course_name'>#{item["course_name"]}</div>"
      else
        acc1
      end

    acc1 =
      if not is_nil(item["detail"]) do
        acc1 <> "
        <div class='details'>#{item["detail"]}</div>"
      else
        acc1
      end

    acc1 =
      if not is_nil(temp) do
        acc1 <> "
        <div class='details'>#{temp}</div>"
      else
        acc1
      end

    acc1 <> "
      #{test_data}
      <p></p>
      "
  end

  def categories_content(acc, category, items) do
    acc <> "
      <div class='row'>
        <div class='col-2'>
          <div class='category_name'>#{category["category"]}</div>
        </div>
        <div class='col-2'>
          <div class='category_name' style='float: right;'>#{category["credits"]}</div>
        </div>
      </div>
      <div class='horizontal_line'></div>
      #{items}
      "
  end

  @spec schedule_content(binary, nil | keyword | map) :: <<_::64, _::_*8>>
  def schedule_content(acc2, z) do
    acc2 <> "
      <div class='items_14'>
        <div class='row'>
          <div class='col-3'>#{z["instructor_name"]}</div>
          <div class='col-3'>#{z["date"]}</div>
          <div class='col-3'>#{z["room"]}</div>
        </div>
      </div>
    "
  end

  def get_file_path do
    'course.json'
    |> Path.relative()
    |> Path.absname()
  end

  def header_content(img) do
    "<!DOCTYPE html>
    <meta charset='UTF-8'>
    <html>
    <header id='header'>
      <div class='header_element'>
          <img class='title-align' src=#{img} width='50px' height='50px'>
          <div class='title-align header_style'><h2><span>Universidad</span><br><span>Europea</h2></div></div><br>
    </header>
    </html>
    <style>

    #header {
      top: 0;
      width: 100%;
      height: 100px;
      padding-bottom: 6%;
    }

    .header_element {
      text-align: center;
      padding-top: 30px;
    }

    .padding {
      padding-left: 35%;
    }
    .title-align {
      display: inline-block;
    }
    .header_style {
      font-family: Calibri, sans-serif;
      margin-top: -85px;
      font-size: 18px;
      font-weight: bold;
      text-align: left;
    }
  </style>
    "
  end

  @doc """
  footer pagination features is in-progress
  """

  @spec footer_content(nil | keyword | map) :: <<_::64, _::_*8>>
  def footer_content(list) do
    "<!DOCTYPE html>
    <meta charset='UTF-8'>
    <html>
    <body onload='subst()'>
    <footer id='footer'>
    <p class='footer_style'>#{list["document"]["footer"]["page_label"]} <span class='page'></span> #{
      list["document"]["footer"]["page_de"]
    } <span class='topage'></span> </p>
    <p class='footer_style'>#{list["document"]["footer"]["text_pagination"]}</p>
    </footer>
    </body>
    </html>
    <style>

    #footer {
      padding-top: 65px;
      padding-bottom: 9mm;
      bottom: 0;
      width: 100%;
      height: 50px;
      font-size: 6px;
    }

    .footer_style{
      font-family: Calibri, sans-serif;
      text-align: center;
      font-size: 10px;
    }
    </style>
    <script>
    function subst() {
            var vars = {};
            var query_strings_from_url = document.location.search.substring(1).split('&');
            for (var query_string in query_strings_from_url) {
                if (query_strings_from_url.hasOwnProperty(query_string)) {
                    var temp_var = query_strings_from_url[query_string].split('=', 2);
                    vars[temp_var[0]] = decodeURI(temp_var[1]);
                }
            }
            var css_selector_classes = ['page', 'topage'];
            for (var css_class in css_selector_classes) {
                if (css_selector_classes.hasOwnProperty(css_class)) {
                    var element = document.getElementsByClassName(css_selector_classes[css_class]);
                    for (var j = 0; j < element.length; ++j) {
                        element[j].textContent = vars[css_selector_classes[css_class]];
                    }
                }
            }
        }
    </script>
    "
  end

  def render_html(list, body, content_text) do
    "<head>
        <meta charset='UTF-8'>
      </head>
      #{render_styles()}
      <body>
        <div id='content' class='body_content'>
          <div class='title_element'>
            <div class='title'>#{list["document"]["header"]["title"]}</div>
            <div style='font-size: 20px;'>#{list["document"]["header"]["program"]}</div>
            <div class='student_section'>
              <div><b>#{list["document"]["header"]["student_label"]}:</b> #{
      list["document"]["header"]["student_value"]
    }</div>
              <div><b>#{list["document"]["header"]["time_label"]}:</b> #{
      list["document"]["header"]["time_value"]
    }</div>
            </div>
            <div class='payment_section'>
              <div><b>#{list["document"]["header"]["level_label"]}:</b> #{
      list["document"]["header"]["level_value"]
    } </div>
              <div><b>#{list["document"]["header"]["payment_label"]}:</b> #{
      list["document"]["header"]["payment_value"]
    }</div>
              <div><b>#{list["document"]["header"]["invoicing_label"]}:</b> #{
      list["document"]["header"]["invoicing_lname"]
    }</div>
            </div>

          <div class='categories'>
          #{body}
          </div>
        </div>
        <div class='raw_text_line'></div>
        <div class='raw_text'>#{content_text}</div>
      </body>
    "
  end

  @doc """
  css styles
  """
  def render_styles do
    "<style>
    body {
      margin-left: 9mm;
      margin-right: 9mm;
      font-family: Calibri, sans-serif;
      line-height: 1.3;
    }
    #footer {
      position: fixed;
      bottom: 0;
      width: 100%;
      height: 50px;
      font-size: 6px;
    }
    /* Print progressive page numbers */
    .page-number:before {
      /* counter-increment: page; */
      content: 'Page: ' counter(page);
    }
    .header_style {
      padding-left: 60px;
      margin-top: -85px;
      font-size: 20px;
    }
    .title-align {
      padding-left: 35%;
    }
    .title {
      font-size: 30px;
    }
    .col-2 {
      float: left;
      width: 50%;
    }
    .col-3 {
      float: left;
      width: 15.33%;
    }
    .row:after {
      content: '';
      display: table;
      clear: both;
    }
    * {
        box-sizing: border-box;
      }
      .column {
        float: left;
        padding: 10px;
        height: 300px;
      }
      .left, .right {
        width: 25%;
      }
      .middle {
        width: 50%;
      }
      .row:after {
        content: '';
        display: table;
        clear: both;
      }
      .course_name {
        font-size: 18px;
        margin: 0
      }
      .details {
        margin: 5px 0 5px 0;
        font-size: 14px;
      }
      .items_14 {
       font-size: 14px;
      }
      .footer_style{
        text-align: center;
        font-size: 10px;
      }
      .category_name {
        font-size: 20px;
      }
      .raw_text {
        font-size: 14px;
        color: grey;
      }
      .raw_text_line {
        margin-top: 24%;
        padding-bottom: 40px;
        border-top: 2px solid #A9A9A9;
      }
      .horizontal_line {
        margin-top: 4px;
        border-top: 2px solid #A9A9A9 ;
        margin-bottom: 20px;
      }
      .student_section {
        font-size: 14px;
        padding: 10px 0 10px 0;
      }
      .payment_section {
        font-size: 14px;
        padding: 10px 0 50px 0;
      }
      .date_style {
        font-size: 14px;
      }
      .header_element {
        padding-top: 50px;
      }
  </style>"
  end

  def image_path do
    'client.png'
    |> Path.relative()
    |> Path.absname()
  end
end
