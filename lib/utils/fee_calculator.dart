class FeeCalculator {
  static double calculateFee(double productCost) {
    if (productCost <= 50) {
      return 10.0;
    } else if (productCost <= 100) {
      return 15.0;
    } else if (productCost <= 150) {
      return 20.0;
    } else {
      // For 151 to 200 (max allowed)
      return 25.0;
    }
  }
}
