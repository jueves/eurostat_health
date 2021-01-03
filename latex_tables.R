# Generate Latex tables
source(per_country.Rmd)

to_latex <- function(old_name) {
  new_name <- str_replace_all(old_name, "_", " ")
  return(new_name)
}

for (i in 1:length(lm_models)) {
  country_name <- get_country_name(names(lm_models)[i])
  # cat("\\section{", country_name, "}\n")
  
  if (!is.null(lm_models[[i]])) {
  #   cat("No se han encontrado suficientes datos para desarrollar un modelo para ",
  #        country_name, ".\n", sep="")
  # } else {
    coef_list <- lm_models[[i]]$coefficients
    cat("\\begin{table}[h]\n")
    cat("\\begin{center}")
    cat("\\caption{", "Coeficientes ", country_name, "}\n")
    cat("\\begin{tabular}{ r | l }\n")
    cat("\\textbf{ Variable } & \\textbf{ Coeficiente }\\\\\n")
    for (j in 1:length(coef_list)) {
      cat("\\hline\n")
      cat(to_latex(names(coef_list)[j]), " & ", to_latex(coef_list[[j]]), "\\\\\n")
    }
    cat("\\end{tabular}\n")
    cat("\\label{table:", country_name, "}\n", sep="")
    cat("\\end{center}\n")
    cat("\\end{table}\n")
  }
}