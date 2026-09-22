library(shiny)
library(ggplot2)
library(bslib)

source(file.path("R", "bold_engine.R"))
source(file.path("R", "boin_engine.R"))
source(file.path("R", "scenarios.R"))
source(file.path("R", "analysis_utils.R"))

method_colors <- c(BOLD = "#087F8C", BOIN = "#C76D00")
presets <- default_scenarios()

scenario_inputs <- function(presets, n_doses) lapply(seq_len(nrow(presets)), function(i) {
  div(
    class = "scenario-input-row",
    style = sprintf("grid-template-columns: 40px repeat(%d, minmax(68px, 1fr));", n_doses),
    span(class = "scenario-state", presets$scenario[i]),
    lapply(seq_len(n_doses), function(j) {
      numericInput(
        sprintf("all_dlt_%d_%d", i, j),
        paste("Dose", j),
        presets[[paste0("dose_", j)]][i],
        min = 0.001, max = 0.999, step = 0.01
      )
    })
  )
})

theme_app <- bs_theme(
  version = 5,
  bg = "#F7F9FB",
  fg = "#17212B",
  primary = "#087F8C",
  secondary = "#566573",
  base_font = font_google("Source Sans 3"),
  heading_font = font_google("Source Sans 3")
)

ui <- navbarPage(
  title = div(class = "brand", "BOLD / BOIN Research Simulator"),
  id = "main_nav",
  theme = theme_app,
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),
  tabPanel(
    "Run simulation",
    div(
      class = "page-band",
      div(
        class = "content-wrap",
        h2("Phase I operating characteristics"),
        p(class = "lead-copy", "Choose a scenario, review the design assumptions, then run the BOLD and BOIN comparison."),
        div(class = "notice", strong("Independent research implementation."), " These simulations support design review. This is not an official BOLD or BOIN app or a validated live-dose decision system.")
      )
    ),
    div(
      class = "content-wrap workspace",
      div(
        class = "control-column",
        h3(span(class = "step", "1"), "Choose what to run"),
        numericInput("n_doses", "Number of dose levels (both designs)", 4, min = 2, max = 10, step = 1),
        selectInput("start_dose", "Starting dose (both designs)", choices = stats::setNames(1:4, paste("Dose", 1:4)), selected = 1),
        selectInput(
          "scenario_choice",
          "True MTD scenario",
          choices = c("All scenarios" = "all", stats::setNames(presets$scenario, paste("True state", presets$scenario))),
          selected = "all"
        ),
        checkboxGroupInput(
          "methods",
          "Designs",
          choices = c("BOLD" = "BOLD", "BOIN" = "BOIN"),
          selected = c("BOLD", "BOIN"),
          inline = TRUE
        ),
        conditionalPanel(
          condition = "input.scenario_choice != 'all'",
          uiOutput("single_dlt_inputs")
        ),
        conditionalPanel(
          condition = "input.scenario_choice == 'all'",
          div(
            class = "scenario-input-list",
            h4("True DLT probabilities"),
            uiOutput("all_dlt_inputs")
          )
        ),
        actionButton("reset_scenarios", "Reset DLT values", icon = icon("undo"), class = "btn-reset"),
        h3(span(class = "step", "2"), "Check design inputs"),
        div(
          class = "input-grid",
          numericInput("phi", "Target DLT rate (phi)", 0.30, min = 0.05, max = 0.60, step = 0.01),
          numericInput("n_trial", "Simulation trials", 500, min = 100, max = 10000, step = 100),
          numericInput("n_max", "Maximum patients", 18, min = 6, max = 100, step = 3),
          numericInput("cohort_size", "Patients per cohort", 3, min = 1, max = 10, step = 1),
          numericInput("n_stop", "Shared per-dose stopping limit", 12, min = 1, max = 100, step = 1),
          numericInput("gamma", "Shared toxicity cutoff (BOIN and BOLD default)", 0.90, min = 0.50, max = 0.999, step = 0.01),
          numericInput("tau", "BOLD PPAT target (tau)", 0.50, min = 0.10, max = 0.90, step = 0.01),
          numericInput("pess", "BOLD common PESS", 3, min = 0.1, max = 30, step = 0.5),
          numericInput("seed", "Random seed", 20260918, min = 1, max = 99999999, step = 1)
        ),
        checkboxInput("custom_bold_prior", "Customize BOLD prior means by dose", FALSE),
        conditionalPanel("input.custom_bold_prior", uiOutput("bold_prior_inputs")),
        checkboxInput("custom_bold_pess", "Customize BOLD PESS by dose", FALSE),
        conditionalPanel("input.custom_bold_pess", uiOutput("bold_pess_inputs")),
        tableOutput("bold_prior_table"),
        checkboxInput("custom_bold_gamma", "Customize BOLD toxicity cutoffs by dose", FALSE),
        conditionalPanel("input.custom_bold_gamma", uiOutput("bold_gamma_inputs")),
        checkboxInput("custom_bold_stop", "Customize BOLD limits by dose", FALSE),
        conditionalPanel("input.custom_bold_stop", uiOutput("bold_stop_inputs")),
        selectInput("boin_stop_rule", "BOIN early-stopping rule",
          choices = c("Limit reached and same dose recommended (matched protocol)" = "stable",
            "Limit reached (standard BOIN)" = "standard"), selected = "stable"),
        p(class = "stopping-note", "BOLD stops at its dose limit only when it recommends the same dose again. BOIN uses the selected rule. Limits count all patients treated at that dose."),
        actionButton("run", "Run comparison", icon = icon("play"), class = "btn-run")
      ),
      div(
        class = "result-column",
        div(
          class = "result-toolbar",
          h3(span(class = "step", "3"), "Read the results"),
          downloadButton("download_results", "Download CSV bundle", icon = icon("download"))
        ),
        uiOutput("run_status"),
        plotOutput("accuracy_plot", height = "360px"),
        h3("Operating-characteristic summary"),
        tableOutput("summary_table")
      )
    )
  ),
  tabPanel(
    "Dose selections",
    div(
      class = "content-wrap tab-content-pad",
      h2("What dose was selected?"),
      p(class = "lead-copy", "Each bar is the percentage of simulated trials ending at that selection."),
      selectInput("selection_scenario", "Scenario to display", choices = presets$scenario, selected = "4", width = "240px"),
      plotOutput("selection_plot", height = "430px"),
      tableOutput("selection_table")
    )
  ),
  tabPanel(
    "Patient allocation",
    div(
      class = "content-wrap tab-content-pad",
      h2("Where were participants treated?"),
      p(class = "lead-copy", "Bars show the average number of participants assigned to each dose."),
      selectInput("allocation_scenario", "Scenario to display", choices = presets$scenario, selected = "4", width = "240px"),
      plotOutput("allocation_plot", height = "430px"),
      tableOutput("allocation_table")
    )
  ),
  tabPanel(
    "Scenario definitions",
    div(
      class = "content-wrap tab-content-pad",
      h2("True-DLT assumptions from the last run"),
      div(class = "notice warning", strong("Confirm before regulatory use."), " These are simulation scenarios, not estimates from real patients."),
      tableOutput("scenario_table"),
      h3("About the default 0.15 separation"),
      p("The paper defines upper delta as the gap from an MTD to the next higher dose. In the default Dose-4 scenario, the 0.15 separation instead refers to the gap to the dose below: 0.25 minus 0.10 equals 0.15. Edited rates may have a different gap."),
      p("For the <1 state, all doses exceed the target. For the above-range state, all available doses remain below target; selecting the highest available dose is treated as the operationally correct available-dose recommendation.")
    )
  ),
  tabPanel(
    "How to use",
    div(
      class = "content-wrap tab-content-pad guide",
      h2("Beginner click guide"),
      div(class = "guide-row", span(class = "step large", "1"), div(h3("Open Run simulation"), p("Choose the number of dose levels and leave 'All scenarios' selected for the full operating-characteristic comparison. Four-dose defaults retain the original scenarios; other dose counts use editable illustrative scenarios."))),
      div(class = "guide-row", span(class = "step large", "2"), div(h3("Review the design settings"), p("Phi 0.30; 500 trials; maximum N 18; cohort size 3; one-dose stopping N 12; gamma 0.90; tau 0.50; PESS 3."))),
      div(class = "guide-row", span(class = "step large", "3"), div(h3("Click Run comparison"), p("Wait for the teal status message. The app simulates BOLD and BOIN under the same true-DLT assumptions."))),
      div(class = "guide-row", span(class = "step large", "4"), div(h3("Read Accuracy first"), p("Accuracy is the percentage of trials that selected the correct state. With 500 trials, Monte Carlo uncertainty is shown as MCSE."))),
      div(class = "guide-row", span(class = "step large", "5"), div(h3("Inspect selections and allocations"), p("Use the other tabs to see which dose was selected and how many participants were treated at each dose."))),
      div(class = "guide-row", span(class = "step large", "6"), div(h3("Download"), p("Click Download CSV bundle to save scenario definitions, summary results, dose-selection percentages, and allocation results."))),
      h3("What BOLD is doing"),
      p("After every cohort, BOLD updates the posterior probability that each dose is above the toxicity target. It uses order-constrained local information to choose whether to escalate, stay, or de-escalate. BOIN uses interval decision boundaries. Both use the selected starting dose and cohort size; the defaults are Dose 1 and three patients. These simulations do not model sentinel timing."),
      tags$a(href = "https://onlinelibrary.wiley.com/doi/full/10.1002/sim.70456", target = "_blank", "Open the BOLD paper"),
      tags$span("  |  "),
      tags$a(href = "https://github.com/hiddenmanna1996/BOLD", target = "_blank", "Open the authors' original code")
    )
  )
)

server <- function(input, output, session) {
  dose_count <- reactive({
    req(input$n_doses)
    validate(need(is.finite(input$n_doses) && input$n_doses == as.integer(input$n_doses) &&
      input$n_doses >= 2 && input$n_doses <= 10, "Choose an integer from 2 to 10 dose levels."))
    as.integer(input$n_doses)
  })
  active_presets <- reactive(default_scenarios(dose_count()))
  output$bold_gamma_inputs <- renderUI({
    req(input$gamma)
    div(class = "input-grid", lapply(seq_len(dose_count()), function(j) {
      old <- isolate(input[[paste0("bold_gamma_", j)]])
      numericInput(paste0("bold_gamma_", j), paste("BOLD Dose", j, "cutoff (gamma)"),
        value = if (is.null(old)) input$gamma else old, min = 0.50, max = 0.999, step = 0.01)
    }))
  })
  bold_cutoffs <- reactive({
    if (!isTRUE(input$custom_bold_gamma)) return(rep(input$gamma, dose_count()))
    vapply(seq_len(dose_count()), function(j) {
      value <- input[[paste0("bold_gamma_", j)]]
      if (is.null(value)) NA_real_ else as.numeric(value)
    }, numeric(1))
  })
  output$bold_prior_inputs <- renderUI({
    req(input$phi)
    div(class = "input-grid", lapply(seq_len(dose_count()), function(j) {
      old <- isolate(input[[paste0("bold_q_", j)]])
      numericInput(paste0("bold_q_", j), paste("BOLD Dose", j, "prior mean (q)"),
        value = if (is.null(old)) input$phi else old, min = 0.001, max = 0.999, step = 0.01)
    }))
  })
  bold_prior_means <- reactive({
    if (!isTRUE(input$custom_bold_prior)) return(rep(input$phi, dose_count()))
    vapply(seq_len(dose_count()), function(j) {
      value <- input[[paste0("bold_q_", j)]]
      if (is.null(value)) NA_real_ else as.numeric(value)
    }, numeric(1))
  })
  output$bold_pess_inputs <- renderUI({
    req(input$pess)
    div(class = "input-grid", lapply(seq_len(dose_count()), function(j) {
      old <- isolate(input[[paste0("bold_m_", j)]])
      numericInput(paste0("bold_m_", j), paste("BOLD Dose", j, "PESS (m)"),
        value = if (is.null(old)) input$pess else old, min = 0.1, max = 30, step = 0.5)
    }))
  })
  bold_pess <- reactive({
    if (!isTRUE(input$custom_bold_pess)) return(rep(input$pess, dose_count()))
    vapply(seq_len(dose_count()), function(j) {
      value <- input[[paste0("bold_m_", j)]]
      if (is.null(value)) NA_real_ else as.numeric(value)
    }, numeric(1))
  })
  output$bold_prior_table <- renderTable({
    q <- bold_prior_means()
    m <- bold_pess()
    req(length(q) == dose_count(), all(is.finite(q)), all(is.finite(m)))
    data.frame(Dose = seq_len(dose_count()), `Prior mean` = q,
      PESS = m, `Beta prior` = sprintf("Beta(%g, %g)", q * m, (1 - q) * m),
      check.names = FALSE)
  }, digits = 3, striped = TRUE, spacing = "s")
  output$bold_stop_inputs <- renderUI({
    req(input$n_stop)
    div(class = "input-grid", lapply(seq_len(dose_count()), function(j) {
      old <- isolate(input[[paste0("bold_stop_", j)]])
      numericInput(paste0("bold_stop_", j), paste("BOLD Dose", j, "limit"),
        value = if (is.null(old)) input$n_stop else old, min = 1, max = 100, step = 1)
    }))
  })
  observeEvent(dose_count(), {
    p <- active_presets()
    starting <- suppressWarnings(as.integer(input$start_dose))
    if (length(starting) != 1L || is.na(starting) || !starting %in% seq_len(dose_count())) starting <- 1L
    updateSelectInput(session, "start_dose",
      choices = stats::setNames(seq_len(dose_count()), paste("Dose", seq_len(dose_count()))), selected = starting)
    updateSelectInput(session, "scenario_choice",
      choices = c("All scenarios" = "all", stats::setNames(p$scenario, paste("True state", p$scenario))),
      selected = "all")
  })
  output$all_dlt_inputs <- renderUI(scenario_inputs(active_presets(), dose_count()))
  output$single_dlt_inputs <- renderUI({
    p <- active_presets()
    state <- input$scenario_choice
    if (is.null(state) || !state %in% p$scenario) state <- as.character(dose_count())
    row <- p[p$scenario == state, ]
    div(class = "dose-inputs", lapply(seq_len(dose_count()), function(j) {
      numericInput(paste0("dlt", j), paste("Dose", j, "true DLT"),
        row[[paste0("dose_", j)]], min = 0.001, max = 0.999, step = 0.01)
    }))
  })
  initial_path <- file.path("results", "simulation_results.rds")
  current_result <- reactiveVal(if (file.exists(initial_path)) readRDS(initial_path) else NULL)
  running <- reactiveVal(FALSE)
  last_message <- reactiveVal("Showing the saved 500-trial analysis. Run comparison to apply edited DLT rates.")

  observeEvent(input$reset_scenarios, {
    presets <- active_presets()
    for (i in seq_len(nrow(presets))) {
      for (j in seq_len(dose_count())) {
        updateNumericInput(
          session, sprintf("all_dlt_%d_%d", i, j),
          value = presets[[paste0("dose_", j)]][i]
        )
      }
    }
    if (!is.null(input$scenario_choice) && input$scenario_choice != "all") {
      row <- presets[presets$scenario == input$scenario_choice, ]
      for (j in seq_len(dose_count())) {
        updateNumericInput(session, paste0("dlt", j), value = row[[paste0("dose_", j)]])
      }
    }
  })

  observeEvent(input$run, {
    req(length(input$methods) > 0)
    start_dose <- suppressWarnings(as.integer(input$start_dose))
    if (length(start_dose) != 1L || is.na(start_dose) || !start_dose %in% seq_len(dose_count())) {
      showNotification("Choose a starting dose within the available dose levels.", type = "error")
      return()
    }
    if (input$n_max %% input$cohort_size != 0) {
      showNotification("Maximum patients must be divisible by cohort size.", type = "error")
      return()
    }

    presets <- active_presets()
    scenario_data <- presets
    if (input$scenario_choice == "all") {
      for (i in seq_len(nrow(scenario_data))) {
        for (j in seq_len(dose_count())) {
          req(!is.null(input[[sprintf("all_dlt_%d_%d", i, j)]]))
          scenario_data[[paste0("dose_", j)]][i] <- input[[sprintf("all_dlt_%d_%d", i, j)]]
        }
      }
    } else {
      scenario_data <- presets[presets$scenario == input$scenario_choice, ]
      req(nrow(scenario_data) == 1L)
      values <- lapply(seq_len(dose_count()), function(j) input[[paste0("dlt", j)]])
      req(all(lengths(values) == 1L))
      scenario_data[1, paste0("dose_", seq_len(dose_count()))] <- unlist(values)
    }

    running(TRUE)
    last_message("Running simulations...")
    result <- tryCatch(
      withProgress(message = "Running BOLD and BOIN", value = 0, {
        incProgress(0.1, detail = "Checking inputs")
        validate_scenarios(scenario_data, input$phi)
        incProgress(0.2, detail = "Simulating trials")
        ans <- run_all_scenarios(
          scenarios = scenario_data,
          phi = input$phi,
          cohort_size = input$cohort_size,
          n_max = input$n_max,
          n_stop_per_dose = input$n_stop,
          gamma = input$gamma,
          bold_gamma = bold_cutoffs(),
          tau = input$tau,
          pess = bold_pess(),
          bold_prior_mean = bold_prior_means(),
          n_trial = input$n_trial,
          seed = input$seed,
          methods = input$methods,
          start_dose = start_dose,
          bold_stop_per_dose = if (isTRUE(input$custom_bold_stop)) {
            vapply(seq_len(dose_count()), function(j) {
              value <- input[[paste0("bold_stop_", j)]]
              if (is.null(value)) NA_real_ else as.numeric(value)
            }, numeric(1))
          } else input$n_stop,
          boin_require_stability = identical(input$boin_stop_rule, "stable")
        )
        incProgress(0.7, detail = "Preparing tables")
        ans
      }),
      error = function(e) {
        showNotification(conditionMessage(e), type = "error", duration = 10)
        NULL
      }
    )
    running(FALSE)
    if (!is.null(result)) {
      current_result(result)
      last_message(sprintf("Complete: %d dose levels; starting at Dose %d; %s simulated trials per scenario.", dose_count(), start_dose, format(input$n_trial, big.mark = ",")))
      updateSelectInput(session, "selection_scenario", choices = result$scenarios$scenario, selected = tail(result$scenarios$scenario, 2)[1])
      updateSelectInput(session, "allocation_scenario", choices = result$scenarios$scenario, selected = tail(result$scenarios$scenario, 2)[1])
    }
  })

  output$run_status <- renderUI({
    cls <- if (running()) "run-status running" else "run-status complete"
    message <- last_message()
    result <- current_result()
    if (!running() && !is.null(result)) {
      result_doses <- length(grep("^dose_[0-9]+$", names(result$scenarios)))
      if (result_doses != dose_count()) {
        message <- sprintf("Showing previous %d-dose results. Run comparison to apply %d dose levels.", result_doses, dose_count())
      } else if (!is.null(input$start_dose)) {
        result_start <- result$parameters$start_dose
        if (is.null(result_start)) result_start <- 1L
        if (result_start != as.integer(input$start_dose)) {
          message <- sprintf("Showing previous results starting at Dose %d. Run comparison to apply the new starting dose.", result_start)
        }
      }
    }
    div(class = cls, icon(if (running()) "spinner" else "check-circle"), message)
  })

  output$accuracy_plot <- renderPlot({
    req(current_result())
    d <- current_result()$summary
    ggplot(d, aes(x = factor(scenario, levels = current_result()$scenarios$scenario), y = accuracy_pct, fill = method)) +
      geom_col(position = position_dodge(width = 0.72), width = 0.64) +
      geom_text(aes(label = sprintf("%.1f", accuracy_pct)), position = position_dodge(width = 0.72), vjust = -0.35, size = 3.6) +
      scale_fill_manual(values = method_colors, breaks = c("BOLD", "BOIN")) +
      scale_y_continuous(limits = c(0, 105), breaks = seq(0, 100, 25), labels = function(x) paste0(x, "%"), expand = expansion(mult = c(0, 0))) +
      labs(x = "True MTD state", y = "Correct selection", fill = NULL) +
      theme_minimal(base_size = 13) +
      theme(panel.grid.minor = element_blank(), legend.position = "top", axis.title.x = element_text(margin = margin(t = 10)))
  })

  output$summary_table <- renderTable({
    req(current_result())
    d <- format_result_tables(current_result())$summary
    names(d) <- c("True state", "Method", "Accuracy (%)", "MCSE (%)", "Mean N", "SD N", "Mean DLTs", "Overdose (%)")
    d
  }, striped = TRUE, bordered = FALSE, spacing = "s")

  output$selection_plot <- renderPlot({
    req(current_result(), input$selection_scenario)
    d <- subset(current_result()$selection, scenario == input$selection_scenario)
    d$selection <- factor(d$selection, levels = unique(d$selection))
    ggplot(d, aes(x = selection, y = selection_pct, fill = method)) +
      geom_col(position = position_dodge(width = 0.72), width = 0.64) +
      scale_fill_manual(values = method_colors, breaks = c("BOLD", "BOIN")) +
      scale_y_continuous(labels = function(x) paste0(x, "%"), limits = c(0, 100)) +
      labs(x = NULL, y = "Trials ending at selection", fill = NULL) +
      theme_minimal(base_size = 14) +
      theme(panel.grid.minor = element_blank(), legend.position = "top")
  })

  output$selection_table <- renderTable({
    req(current_result(), input$selection_scenario)
    d <- subset(format_result_tables(current_result())$selection, scenario == input$selection_scenario)
    names(d) <- c("True state", "Method", "Final selection", "Percent")
    d
  }, striped = TRUE, spacing = "s")

  output$allocation_plot <- renderPlot({
    req(current_result(), input$allocation_scenario)
    d <- subset(current_result()$allocation, scenario == input$allocation_scenario)
    d$dose <- factor(d$dose, levels = unique(d$dose))
    ggplot(d, aes(x = dose, y = mean_patients, fill = method)) +
      geom_col(position = position_dodge(width = 0.72), width = 0.64) +
      scale_fill_manual(values = method_colors, breaks = c("BOLD", "BOIN")) +
      scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
      labs(x = NULL, y = "Average participants", fill = NULL) +
      theme_minimal(base_size = 14) +
      theme(panel.grid.minor = element_blank(), legend.position = "top")
  })

  output$allocation_table <- renderTable({
    req(current_result(), input$allocation_scenario)
    d <- subset(format_result_tables(current_result())$allocation, scenario == input$allocation_scenario)
    names(d) <- c("True state", "Method", "Dose", "Mean participants")
    d
  }, striped = TRUE, spacing = "s")

  output$scenario_table <- renderTable({
    req(current_result())
    d <- current_result()$scenarios
    names(d) <- c("True state", "Meaning", paste("Dose", seq_len(ncol(d) - 2L)))
    d
  }, striped = TRUE, spacing = "m")

  output$download_results <- downloadHandler(
    filename = function() paste0("bold_boin_results_", Sys.Date(), ".zip"),
    content = function(file) {
      req(current_result())
      tables <- format_result_tables(current_result())
      temp_dir <- tempfile("bold_boin_results_")
      dir.create(temp_dir)
      utils::write.csv(current_result()$scenarios, file.path(temp_dir, "scenario_definitions.csv"), row.names = FALSE)
      parameters <- current_result()$parameters
      parameter_table <- data.frame(parameter = names(parameters),
        value = vapply(parameters, function(x) paste(x, collapse = "; "), character(1)))
      utils::write.csv(parameter_table, file.path(temp_dir, "design_parameters.csv"), row.names = FALSE)
      utils::write.csv(tables$summary, file.path(temp_dir, "operating_characteristics.csv"), row.names = FALSE)
      utils::write.csv(tables$selection, file.path(temp_dir, "dose_selection_percentages.csv"), row.names = FALSE)
            utils::write.csv(tables$allocation, file.path(temp_dir, "mean_patient_allocation.csv"), row.names = FALSE)
      old <- setwd(temp_dir)
      on.exit(setwd(old), add = TRUE)
      utils::zip(file, list.files(temp_dir))
    },
    contentType = "application/zip"
  )
}

shinyApp(ui, server)
