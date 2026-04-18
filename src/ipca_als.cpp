// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>
using namespace Rcpp;

// [[Rcpp::export]]
List ipca_als_cpp(List ret_list, List Z_list,
                 int K, int max_iter, double tol) {

  int T = ret_list.size();

  // --- Determine L from first non-empty Z_t ---
  int L = 0;
  for (int t = 0; t < T; t++) {
    arma::mat Zt = as<arma::mat>(Z_list[t]);
    if (Zt.n_rows > 0) { L = Zt.n_cols; break; }
  }

  // --- Initialization: build M (L x T), column t = Z_t' r_t ---
  arma::mat M(L, T, arma::fill::zeros);
  for (int t = 0; t < T; t++) {
    arma::vec rt  = as<arma::vec>(ret_list[t]);
    arma::mat Zt  = as<arma::mat>(Z_list[t]);
    if (rt.n_elem > 0) M.col(t) = Zt.t() * rt;
  }
  arma::mat U; arma::vec s_init; arma::mat V_init;
  arma::svd_econ(U, s_init, V_init, M);
  if (K > (int)U.n_cols) {
    Rcpp::stop("ipca_als_cpp: K (%d) exceeds min(L, T) = %d. Reduce nfac.", K, (int)U.n_cols);
  }
  arma::mat Gamma = U.cols(0, K - 1);   // L x K

  arma::mat F_mat(T, K, arma::fill::zeros);
  arma::mat Gamma_old = Gamma;
  bool converged = false;

  for (int iter = 0; iter < max_iter; iter++) {

    // --- Factor step: solve K x K system for each t ---
    for (int t = 0; t < T; t++) {
      arma::vec rt = as<arma::vec>(ret_list[t]);
      arma::mat Zt = as<arma::mat>(Z_list[t]);
      if (rt.n_elem == 0) continue;

      arma::mat A = Gamma.t() * Zt.t() * Zt * Gamma;   // K x K
      arma::vec b = Gamma.t() * Zt.t() * rt;            // K x 1
      arma::vec ft;
      // arma::solve returns false (does not throw) when no_approx is absent
      bool ok = arma::solve(ft, A, b, arma::solve_opts::likely_sympd);
      if (!ok) {
        // Ridge fallback for near-singular A
        A.diag() += 1e-8;
        bool ok2 = arma::solve(ft, A, b);
        if (!ok2) ft.zeros();
      }
      F_mat.row(t) = ft.t();
    }

    // --- Loading step: Kronecker-vectorized pooled OLS (Kelly et al. eq. 12) ---
    // vec(Gamma) = LHS^{-1} RHS
    // LHS = sum_t kron(f_t f_t', Z_t' Z_t)   [KL x KL]
    // RHS = vec( sum_t Z_t' r_t f_t' )        [KL x 1]
    // Armadillo is column-major: vec stacks columns of L x K Gamma.
    // kron order: kron(K x K, L x L) = KL x KL — consistent with vec(Gamma).
    arma::mat LHS(K * L, K * L, arma::fill::zeros);
    arma::mat RHS_mat(L, K, arma::fill::zeros);
    for (int t = 0; t < T; t++) {
      arma::vec rt = as<arma::vec>(ret_list[t]);
      arma::mat Zt = as<arma::mat>(Z_list[t]);
      if (rt.n_elem == 0) continue;
      arma::vec ft = F_mat.row(t).t();
      LHS     += arma::kron(ft * ft.t(), Zt.t() * Zt);
      RHS_mat += Zt.t() * rt * ft.t();
    }
    arma::vec rhs_vec = arma::vectorise(RHS_mat);   // stacks columns
    arma::vec g_vec;
    bool ok_load = arma::solve(g_vec, LHS, rhs_vec);
    if (!ok_load) {
      LHS.diag() += 1e-8;
      bool ok_load2 = arma::solve(g_vec, LHS, rhs_vec);
      if (!ok_load2) g_vec.zeros();
    }
    Gamma = arma::reshape(g_vec, L, K);             // fills columns

    // --- Normalize: thin SVD of Gamma ---
    arma::mat Usvd, Vsvd;
    arma::vec sv_norm;
    arma::svd_econ(Usvd, sv_norm, Vsvd, Gamma);
    Gamma = Usvd.cols(0, K - 1);                    // L x K, Gamma'Gamma = I_K
    // Rotate F to preserve fitted values: F_new = F * V * diag(sv)
    F_mat = F_mat * Vsvd * arma::diagmat(sv_norm);

    // Sign convention: flip so largest-abs element of each Gamma column is positive
    for (int k = 0; k < K; k++) {
      arma::uword idx;
      idx = arma::abs(Gamma.col(k)).index_max();
      if (Gamma(idx, k) < 0.0) {
        Gamma.col(k) *= -1.0;
        F_mat.col(k) *= -1.0;
      }
    }

    // --- Convergence ---
    double diff = arma::norm(Gamma - Gamma_old, "fro");
    Gamma_old = Gamma;
    if (diff < tol) { converged = true; break; }
  }

  if (!converged) {
    Rcpp::warning("ipca_est: ALS did not converge in %d iterations", max_iter);
  }

  // Compute sv as variance (mean squared) of each factor column — informative eigval analog
  arma::vec sv(K);
  for (int k = 0; k < K; k++) {
    sv(k) = arma::mean(arma::square(F_mat.col(k)));
  }

  return List::create(Named("Gamma") = Gamma,
                      Named("F")     = F_mat,
                      Named("sv")    = sv);
}
