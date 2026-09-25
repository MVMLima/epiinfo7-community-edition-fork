param([Parameter(Mandatory)][string]$Map, [Parameter(Mandatory)][string]$OutStrings, [Parameter(Mandatory)][string]$OutCs)
# StatCalc (EpiDashboard\StatCalc\*.xaml): gera as chaves de DashboardSharedStrings (TSV para add_code_strings.ps1)
# e o dicionario ingles->chave de StatCalcLocalizer.cs. Map = TSV Ingles<TAB>Portugues (\n = quebra de linha). ASCII puro.
$ErrorActionPreference = 'Stop'
$entries = New-Object System.Collections.Generic.List[object]
foreach ($l in [IO.File]::ReadAllLines($Map, [Text.Encoding]::UTF8)) {
    if ([string]::IsNullOrWhiteSpace($l)) { continue }
    $p = $l -split "`t", 2
    if ($p[0].Trim() -ceq $p[1].Trim()) { continue }
    $entries.Add([pscustomobject]@{ En = $p[0].Trim(); Pt = $p[1].TrimEnd() })
}
$used = @{}; $lines = New-Object System.Text.StringBuilder; $cs = New-Object System.Text.StringBuilder
foreach ($e in ($entries | Sort-Object En)) {
    $base = (($e.En.Replace('\n', ' ').ToUpperInvariant()) -replace '[^A-Z0-9]+', '_').Trim('_')
    if ($base.Length -gt 40) { $base = $base.Substring(0, 40).Trim('_') }
    $k = 'SC_' + $base; $n = 2; $k0 = $k
    while ($used.ContainsKey($k)) { $k = $k0 + '_' + $n; $n++ }
    $used[$k] = 1
    [void]$lines.Append("Dashboard`t$k`t$($e.En)`t$($e.Pt)`n")
    $lit = $e.En.Replace('\n', '\n').Replace('"', '\"')
    [void]$cs.Append("            { `"$lit`", `"$k`" },`r`n")
}
[IO.File]::WriteAllText($OutStrings, $lines.ToString(), (New-Object Text.UTF8Encoding($false)))
$src = @"
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
$($cs.ToString())        };

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
"@
[IO.File]::WriteAllText($OutCs, $src, (New-Object Text.UTF8Encoding($true)))
"entradas: $($entries.Count)"
