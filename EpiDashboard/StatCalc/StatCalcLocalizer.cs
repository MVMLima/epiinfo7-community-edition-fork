using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;

namespace EpiDashboard.StatCalc
{
    /// <summary>
    /// Traduz os textos fixos em ingles dos XAML das calculadoras do StatCalc (pt-BR e outros idiomas):
    /// percorre a arvore logica e troca cada texto conhecido pelo valor de DashboardSharedStrings.
    /// Textos desconhecidos (nomes de metodos como Kelsey/Fleiss, resultados calculados) ficam como estao.
    /// </summary>
    internal static class StatCalcLocalizer
    {
        private static readonly Dictionary<string, string> Keys = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            { "% outcome in exposed group:", "SC_OUTCOME_IN_EXPOSED_GROUP" },
            { "% outcome in unexposed group:", "SC_OUTCOME_IN_UNEXPOSED_GROUP" },
            { "0.5 has been added to each cell for calculations.", "SC_0_5_HAS_BEEN_ADDED_TO_EACH_CELL_FOR_CALC" },
            { "1 Tailed P", "SC_1_TAILED_P" },
            { "2 Tailed P", "SC_2_TAILED_P" },
            { "95% confidence\ninterval", "SC_95_CONFIDENCE_INTERVAL" },
            { "Aberration Detection", "SC_ABERRATION_DETECTION" },
            { "Acceptable Margin of Error:", "SC_ACCEPTABLE_MARGIN_OF_ERROR" },
            { "Add Row", "SC_ADD_ROW" },
            { "Adjusted", "SC_ADJUSTED" },
            { "Adjusted (MH)", "SC_ADJUSTED_MH" },
            { "Adjusted (MLE)", "SC_ADJUSTED_MLE" },
            { "Analysis For Linear Trends In Proportions", "SC_ANALYSIS_FOR_LINEAR_TRENDS_IN_PROPORTION" },
            { "Binomial - Proportion vs. Standard", "SC_BINOMIAL_PROPORTION_VS_STANDARD" },
            { "Cases", "SC_CASES" },
            { "Chi Square", "SC_CHI_SQUARE" },
            { "Chi Square for linear trend", "SC_CHI_SQUARE_FOR_LINEAR_TREND" },
            { "Chi Square for linear trend\n(Extended Mantel-Haenszel)", "SC_CHI_SQUARE_FOR_LINEAR_TREND_EXTENDED_MAN" },
            { "Cluster\nSize", "SC_CLUSTER_SIZE" },
            { "Clusters:", "SC_CLUSTERS" },
            { "Col %", "SC_COL" },
            { "Confidence\nLevel", "SC_CONFIDENCE_LEVEL" },
            { "Controls", "SC_CONTROLS" },
            { "Corrected", "SC_CORRECTED" },
            { "Corrected (MH)", "SC_CORRECTED_MH" },
            { "Count (Optional):", "SC_COUNT_OPTIONAL" },
            { "Crude", "SC_CRUDE" },
            { "Crude (MLE)", "SC_CRUDE_MLE" },
            { "Crude\n(Cross Product)", "SC_CRUDE_CROSS_PRODUCT" },
            { "Date:", "SC_DATE" },
            { "Design effect:", "SC_DESIGN_EFFECT" },
            { "Disease", "SC_DISEASE" },
            { "EARS Properties", "SC_EARS_PROPERTIES" },
            { "Estimate", "SC_ESTIMATE" },
            { "Exact", "SC_EXACT" },
            { "Expected # of events:", "SC_EXPECTED_OF_EVENTS" },
            { "Expected frequency:", "SC_EXPECTED_FREQUENCY" },
            { "Expected percentage:", "SC_EXPECTED_PERCENTAGE" },
            { "Exposed", "SC_EXPOSED" },
            { "Exposure", "SC_EXPOSURE" },
            { "Exposure Score", "SC_EXPOSURE_SCORE" },
            { "Fisher Exact", "SC_FISHER_EXACT" },
            { "Fisher-Exact", "SC_FISHER_EXACT_2" },
            { "Fleiss\nw/ CC", "SC_FLEISS_W_CC" },
            { "For simple random sampling, leave design effect and clusters equal to 1.", "SC_FOR_SIMPLE_RANDOM_SAMPLING_LEAVE_DESIGN" },
            { "Indicator (Optional):", "SC_INDICATOR_OPTIONAL" },
            { "Lag time (days):", "SC_LAG_TIME_DAYS" },
            { "Lower", "SC_LOWER" },
            { "Matched Pair Case-Control Study", "SC_MATCHED_PAIR_CASE_CONTROL_STUDY" },
            { "Mid-P Exact", "SC_MID_P_EXACT" },
            { "MLE Odds Ratio\n(Mid-P)", "SC_MLE_ODDS_RATIO_MID_P" },
            { "No", "SC_NO" },
            { "Not Exposed", "SC_NOT_EXPOSED" },
            { "Numerator:", "SC_NUMERATOR" },
            { "Observed # of events:", "SC_OBSERVED_OF_EVENTS" },
            { "Odds Ratio", "SC_ODDS_RATIO" },
            { "Odds ratio:", "SC_ODDS_RATIO_2" },
            { "Odds-based Parameters", "SC_ODDS_BASED_PARAMETERS" },
            { "Odds-based parameters", "SC_ODDS_BASED_PARAMETERS_2" },
            { "Outcome", "SC_OUTCOME" },
            { "p value", "SC_P_VALUE" },
            { "Percent of cases with exposure:", "SC_PERCENT_OF_CASES_WITH_EXPOSURE" },
            { "Percent of controls exposed:", "SC_PERCENT_OF_CONTROLS_EXPOSED" },
            { "Poisson - Rare Event vs. Standard", "SC_POISSON_RARE_EVENT_VS_STANDARD" },
            { "Population size:", "SC_POPULATION_SIZE" },
            { "Population survey or descriptive study", "SC_POPULATION_SURVEY_OR_DESCRIPTIVE_STUDY" },
            { "Population survey or descriptive study\nFor simple random sampling, leave design effect and clusters equal to 1.", "SC_POPULATION_SURVEY_OR_DESCRIPTIVE_STUDY_F" },
            { "Power:", "SC_POWER" },
            { "Print...", "SC_PRINT" },
            { "Probability that the number of case", "SC_PROBABILITY_THAT_THE_NUMBER_OF_CASE" },
            { "Probability that the number\nof events found is", "SC_PROBABILITY_THAT_THE_NUMBER_OF_EVENTS_FO" },
            { "Ratio (Unexposed : Exposed):", "SC_RATIO_UNEXPOSED_EXPOSED" },
            { "Ratio of controls to cases:", "SC_RATIO_OF_CONTROLS_TO_CASES" },
            { "Risk Difference", "SC_RISK_DIFFERENCE" },
            { "Risk Ratio", "SC_RISK_RATIO" },
            { "Risk ratio:", "SC_RISK_RATIO_2" },
            { "Risk-based Parameters", "SC_RISK_BASED_PARAMETERS" },
            { "Row %", "SC_ROW" },
            { "Run Gadget", "SC_RUN_GADGET" },
            { "Save As Image...", "SC_SAVE_AS_IMAGE" },
            { "StatCalc - 2x2 Tables", "SC_STATCALC_2X2_TABLES" },
            { "StatCalc - Chi Square for Trend", "SC_STATCALC_CHI_SQUARE_FOR_TREND" },
            { "StatCalc - Sample Size and Power", "SC_STATCALC_SAMPLE_SIZE_AND_POWER" },
            { "Statistical Tests", "SC_STATISTICAL_TESTS" },
            { "Strata 1", "SC_STRATA_1" },
            { "Strata 2", "SC_STRATA_2" },
            { "Strata 3", "SC_STRATA_3" },
            { "Strata 4", "SC_STRATA_4" },
            { "Strata 5", "SC_STRATA_5" },
            { "Strata 6", "SC_STRATA_6" },
            { "Strata 7", "SC_STRATA_7" },
            { "Strata 8", "SC_STRATA_8" },
            { "Strata 9", "SC_STRATA_9" },
            { "Summary Results", "SC_SUMMARY_RESULTS" },
            { "Threshold (Std. Deviations):", "SC_THRESHOLD_STD_DEVIATIONS" },
            { "Total observations:", "SC_TOTAL_OBSERVATIONS" },
            { "Total\nSample", "SC_TOTAL_SAMPLE" },
            { "Two-sided confidence level:", "SC_TWO_SIDED_CONFIDENCE_LEVEL" },
            { "Two-tailed p-value", "SC_TWO_TAILED_P_VALUE" },
            { "Uncorrected", "SC_UNCORRECTED" },
            { "Uncorrected\n(MH)", "SC_UNCORRECTED_MH" },
            { "Unexposed", "SC_UNEXPOSED" },
            { "Unmatched Case-Control Study", "SC_UNMATCHED_CASE_CONTROL_STUDY" },
            { "Unmatched Case-Control Study (Comparison of ILL and NOT ILL)", "SC_UNMATCHED_CASE_CONTROL_STUDY_COMPARISON" },
            { "Unmatched Cohort and Cross-Sectional Studies (Exposed and Nonexposed)", "SC_UNMATCHED_COHORT_AND_CROSS_SECTIONAL_STU" },
            { "Unmatched Cohort and Cross-Sectional\nStudies (Exposed and Nonexposed)", "SC_UNMATCHED_COHORT_AND_CROSS_SECTIONAL_STU_2" },
            { "Upper", "SC_UPPER" },
            { "Yes", "SC_YES" },
        };

        private static string Normalize(string s)
        {
            if (s == null) return null;
            s = s.Replace("\r\n", "\n").Replace('\r', '\n');
            s = Regex.Replace(s, @"[ \t]*\n[ \t]*", "\n");
            s = Regex.Replace(s, @"[ \t]+", " ");
            return s.Trim();
        }

        private static string Translate(string english)
        {
            string key;
            string norm = Normalize(english);
            if (norm == null || !Keys.TryGetValue(norm, out key)) return null;
            string value = DashboardSharedStrings.ResourceManager.GetString(key, DashboardSharedStrings.Culture);
            return string.IsNullOrEmpty(value) ? null : value;
        }

        internal static void Apply(DependencyObject root)
        {
            if (root == null) return;

            TextBlock textBlock = root as TextBlock;
            if (textBlock != null)
            {
                ApplyToTextBlock(textBlock);
            }

            ContentControl contentControl = root as ContentControl;
            if (contentControl != null)
            {
                string content = contentControl.Content as string;
                string translated = content == null ? null : Translate(content);
                if (translated != null) contentControl.Content = translated;
            }

            HeaderedContentControl headeredContent = root as HeaderedContentControl;
            if (headeredContent != null)
            {
                string header = headeredContent.Header as string;
                string translated = header == null ? null : Translate(header);
                if (translated != null) headeredContent.Header = translated;
            }

            HeaderedItemsControl headeredItems = root as HeaderedItemsControl;
            if (headeredItems != null)
            {
                string header = headeredItems.Header as string;
                string translated = header == null ? null : Translate(header);
                if (translated != null) headeredItems.Header = translated;
            }

            FrameworkElement element = root as FrameworkElement;
            if (element != null)
            {
                string tip = element.ToolTip as string;
                string translatedTip = tip == null ? null : Translate(tip);
                if (translatedTip != null) element.ToolTip = translatedTip;
                if (element.ContextMenu != null) Apply(element.ContextMenu);
            }

            foreach (object child in LogicalTreeHelper.GetChildren(root))
            {
                DependencyObject dependencyChild = child as DependencyObject;
                if (dependencyChild != null) Apply(dependencyChild);
            }
        }

        private static void ApplyToTextBlock(TextBlock textBlock)
        {
            // Junta os textos das Run e LineBreak (Inlines) em uma unica string com \n.
            System.Text.StringBuilder builder = new System.Text.StringBuilder();
            foreach (Inline inline in textBlock.Inlines)
            {
                Run run = inline as Run;
                if (run != null) builder.Append(run.Text);
                else if (inline is LineBreak) builder.Append('\n');
                else return; // formatacao complexa: nao mexe
            }
            string translated = Translate(builder.ToString());
            if (translated == null) return;

            string[] parts = translated.Replace("\r\n", "\n").Split('\n');
            textBlock.Inlines.Clear();
            for (int i = 0; i < parts.Length; i++)
            {
                if (i > 0) textBlock.Inlines.Add(new LineBreak());
                textBlock.Inlines.Add(new Run(parts[i]));
            }
        }
    }
}