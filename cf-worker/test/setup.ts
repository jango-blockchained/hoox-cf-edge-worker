// Mock fetch if needed
global.fetch = jest.fn(() =>
    Promise.resolve({
        json: () => Promise.resolve({}),
    })
) as jest.Mock;

// Clear all mocks before each test
beforeEach(() => {
    jest.clearAllMocks();
}); 